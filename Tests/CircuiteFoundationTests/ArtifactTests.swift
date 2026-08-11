import CircuiteFoundation
import CircuiteFoundationCrypto
import CircuiteFoundationFoundation
import CircuiteFoundationFileSystem
import Foundation
import Testing

@Suite
struct ArtifactTests {
  @Test
  func sha256DigestMatchesKnownValue() throws {
    let data = Data("hello".utf8)

    let digest = try SHA256ContentDigester().digest(data: data, using: .sha256)

    #expect(
      digest.hexadecimalValue
        == "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
    )
  }

  @Test
  func incrementalDigestMatchesKnownValueThroughExistential() throws {
    let digester: any ContentDigesting = SHA256ContentDigester()
    let limits = try ContentDigestSessionLimits(
      maximumChunkByteCount: 3,
      maximumTotalByteCount: 5,
      maximumUpdateCount: 2
    )

    let result = try digester.digest(using: .sha256, limits: limits) {
      (lease: borrowing ContentDigestUpdateLease) throws(ContentDigestError) in
      try lease.update(Array("hel".utf8))
      try lease.update(Array("lo".utf8))
    }

    #expect(result.digest.hexadecimalValue == "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
    #expect(result.totalByteCount == 5)
    #expect(result.updateCount == 2)
  }

  @Test
  func incrementalDigestRejectsChunkBeforeBackendMutation() throws {
    let limits = try ContentDigestSessionLimits(
      maximumChunkByteCount: 2,
      maximumTotalByteCount: 4,
      maximumUpdateCount: 2
    )

    #expect(throws: ContentDigestError.chunkByteLimitExceeded(limit: 2, requested: 3)) {
      _ = try SHA256ContentDigester().digest(using: .sha256, limits: limits) {
        (lease: borrowing ContentDigestUpdateLease) throws(ContentDigestError) in
        try lease.update([0x01, 0x02, 0x03])
      }
    }
  }

  @Test
  func incrementalDigestRejectsUpdateCountOverflow() throws {
    let limits = try ContentDigestSessionLimits(
      maximumChunkByteCount: 1,
      maximumTotalByteCount: 2,
      maximumUpdateCount: 1
    )

    #expect(throws: ContentDigestError.updateCountLimitExceeded(limit: 1, requested: 2)) {
      _ = try SHA256ContentDigester().digest(using: .sha256, limits: limits) {
        (lease: borrowing ContentDigestUpdateLease) throws(ContentDigestError) in
        try lease.update([0x01])
        try lease.update([0x02])
      }
    }
  }

  @Test
  func incrementalDigestRejectsZeroLimits() {
    #expect(throws: ContentDigestError.self) {
      _ = try ContentDigestSessionLimits(
        maximumChunkByteCount: 0,
        maximumTotalByteCount: 1,
        maximumUpdateCount: 1
      )
    }
  }

  @Test
  func relativeLocationRejectsTraversal() {
    #expect(throws: ArtifactLocationError.self) {
      try ArtifactLocation(workspaceRelativePath: "reports/../outside.json")
    }
  }

  @Test
  func relativeArtifactPathRejectsTraversalAndSeparators() {
    #expect(throws: ArtifactRelativePathError.reservedSegment(index: 1, value: "..")) {
      _ = try ArtifactRelativePath(segments: ["reports", "..", "outside.json"])
    }
    #expect(throws: ArtifactRelativePathError.separatorInSegment(index: 0, value: "reports/timing.json")) {
      _ = try ArtifactRelativePath(segments: ["reports/timing.json"])
    }
  }

  @Test
  func artifactAvailabilityKeepsLocationSeparateFromReference() throws {
    let reference = try makeReference(path: "reports/timing.json", digestByte: "a")
    let availability = ArtifactAvailability.local(
      artifactID: reference.id,
      rootID: try ArtifactRootID(rawValue: "workspace-root"),
      relativePath: try ArtifactRelativePath(segments: ["reports", "timing.json"])
    )

    let encoded = try JSONEncoder().encode(availability)
    let decoded = try JSONDecoder().decode(ArtifactAvailability.self, from: encoded)

    #expect(decoded == availability)
    #expect(decoded.artifactID == reference.id)
  }

  @Test
  func artifactAccessIntentRejectsMismatchedAvailability() throws {
    let expected = try makeReference(path: "reports/timing.json", digestByte: "a")
    let other = try makeReference(path: "reports/other.json", digestByte: "b")
    let availability = ArtifactAvailability.local(
      artifactID: other.id,
      rootID: try ArtifactRootID(rawValue: "workspace-root"),
      relativePath: try ArtifactRelativePath(segments: ["reports", "timing.json"])
    )
    let budget = try ArtifactAccessBudget(
      maximumPageByteCount: 64,
      maximumTotalByteCount: 128,
      maximumPageCount: 2,
      maximumWorkUnitCount: 4,
      maximumDurationNanoseconds: 1_000_000
    )

    #expect(
      throws: ArtifactAccessIntentError.availabilityIdentityMismatch(
        expected: expected.id,
        actual: other.id
      )
    ) {
      _ = try ArtifactAccessIntent(
        expectedReference: expected,
        availability: availability,
        operation: .read,
        budget: budget
      )
    }
  }

  @Test
  func artifactAccessIntentAdapterRoundTripsAndRevalidatesIdentity() throws {
    let expected = try makeReference(path: "reports/timing.json", digestByte: "a")
    let other = try makeReference(path: "reports/other.json", digestByte: "b")
    let availability = ArtifactAvailability.local(
      artifactID: expected.id,
      rootID: try ArtifactRootID(rawValue: "workspace-root"),
      relativePath: try ArtifactRelativePath(segments: ["reports", "timing.json"])
    )
    let otherAvailability = ArtifactAvailability.local(
      artifactID: other.id,
      rootID: try ArtifactRootID(rawValue: "workspace-root"),
      relativePath: try ArtifactRelativePath(segments: ["reports", "other.json"])
    )
    let intent = try ArtifactAccessIntent(
      expectedReference: expected,
      availability: availability,
      operation: .verify,
      budget: ArtifactAccessBudget(
        maximumPageByteCount: 64,
        maximumTotalByteCount: 128,
        maximumPageCount: 2,
        maximumWorkUnitCount: 4,
        maximumDurationNanoseconds: 1_000_000
      )
    )
    let encoded = try JSONEncoder().encode(intent)

    #expect(try JSONDecoder().decode(ArtifactAccessIntent.self, from: encoded) == intent)

    var object = try #require(
      JSONSerialization.jsonObject(with: encoded) as? [String: Any]
    )
    object["availability"] = try JSONSerialization.jsonObject(
      with: JSONEncoder().encode(otherAvailability)
    )
    let mismatched = try JSONSerialization.data(withJSONObject: object)
    #expect(
      throws: ArtifactAccessIntentError.availabilityIdentityMismatch(
        expected: expected.id,
        actual: other.id
      )
    ) {
      _ = try JSONDecoder().decode(ArtifactAccessIntent.self, from: mismatched)
    }
  }

  @Test
  func terminalArtifactPageRequiresFinalReceipt() throws {
    let work = ArtifactAccessWorkReport(
      pageCount: 1,
      workUnitCount: 1,
      elapsedNanoseconds: 10
    )

    #expect(throws: ArtifactReadPageError.missingReceiptAtCompletion) {
      _ = try ArtifactReadPage(
        offset: 0,
        bytes: TestArtifactBytes(bytes: [0x01]),
        cumulativeByteCount: 1,
        cumulativeWork: work,
        completion: .complete,
        finalReceipt: nil
      )
    }
  }

  @Test
  func absoluteLocationDecoderReportsInvalidFileURL() {
    let data = Data(#"{"storage":"absoluteFileURL","value":"http://["}"#.utf8)

    #expect(throws: ArtifactLocationError.invalidFileURL("http://[")) {
      _ = try JSONDecoder().decode(ArtifactLocation.self, from: data)
    }
  }

  @Test
  func relativeLocationRejectsSymlinkEscape() throws {
    try withTemporaryDirectory { temporaryDirectory in
      let workspace = temporaryDirectory.appendingPathComponent("workspace", isDirectory: true)
      let outside = temporaryDirectory.appendingPathComponent("outside", isDirectory: true)
      try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
      try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
      let outsideFile = outside.appendingPathComponent("evidence.json")
      try Data("outside".utf8).write(to: outsideFile)
      let link = workspace.appendingPathComponent("linked", isDirectory: true)
      try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
      let location = try ArtifactLocation(workspaceRelativePath: "linked/evidence.json")

      #expect(throws: ArtifactLocationError.self) {
        try location.resolvedFileURL(relativeTo: workspace)
      }
    }
  }

  @Test
  func referenceCapturesAndVerifierChecksImmutableContent() throws {
    try withTemporaryDirectory { workspace in
      let reports = workspace.appendingPathComponent("reports", isDirectory: true)
      try FileManager.default.createDirectory(at: reports, withIntermediateDirectories: true)
      let reportURL = reports.appendingPathComponent("timing.json")
      try Data("accepted".utf8).write(to: reportURL)
      let location = try ArtifactLocation(workspaceRelativePath: "reports/timing.json")
      let locator = ArtifactLocator(location: location, role: .output, kind: .report, format: .json)
      let reference = try LocalArtifactReferencer(digester: SHA256ContentDigester()).reference(
        locator,
        relativeTo: workspace
      )

      #expect(reference.byteCount == 8)
      #expect(
        LocalArtifactVerifier(digester: SHA256ContentDigester())
          .verify(reference, at: locator, relativeTo: workspace).isVerified
      )

      try Data("modified".utf8).write(to: reportURL)
      let integrity = LocalArtifactVerifier(digester: SHA256ContentDigester())
        .verify(reference, at: locator, relativeTo: workspace)

      #expect(!integrity.isVerified)
      #expect(
        integrity.issues.contains { $0.code == .digestMismatch }
      )
    }
  }

  @Test
  func referencerRejectsFilesThatChangeDuringDigesting() throws {
    try withTemporaryDirectory { workspace in
      let fileURL = workspace.appendingPathComponent("changing.json")
      try Data("before".utf8).write(to: fileURL)
      let location = try ArtifactLocation(workspaceRelativePath: "changing.json")
      let locator = ArtifactLocator(location: location, role: .output, kind: .report, format: .json)
      let referencer = LocalArtifactReferencer(digester: MutatingDigester(fileURL: fileURL))

      #expect(throws: ArtifactReferenceError.changedDuringReference(fileURL)) {
        try referencer.reference(locator, relativeTo: workspace)
      }
    }
  }

  @Test
  func artifactReferenceRoundTripsThroughJSON() throws {
    let digest = try ContentDigest(
      algorithm: .sha256,
      hexadecimalValue: String(repeating: "a", count: 64)
    )
    let reference = try ArtifactReference(
      digest: digest,
      byteCount: 128,
      descriptor: ArtifactDescriptor(role: .output, kind: .parasitics, format: .spef)
    )

    let encoded = try JSONEncoder().encode(reference)
    let decoded = try JSONDecoder().decode(ArtifactReference.self, from: encoded)

    #expect(decoded == reference)
  }

  @Test
  func artifactReferenceRejectsMissingIdentity() throws {
    let digest = try ContentDigest(
      algorithm: .sha256,
      hexadecimalValue: String(repeating: "a", count: 64)
    )
    let reference = try ArtifactReference(
      digest: digest,
      byteCount: 128,
      descriptor: ArtifactDescriptor(role: .output, kind: .parasitics, format: .spef)
    )
    let encoded = try JSONEncoder().encode(reference)
    var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    object.removeValue(forKey: "id")
    let incomplete = try JSONSerialization.data(withJSONObject: object)

    #expect(throws: DecodingError.self) {
      _ = try JSONDecoder().decode(ArtifactReference.self, from: incomplete)
    }
  }

  @Test
  func artifactReferenceFixturePreservesPublicSchema() throws {
    let fixtureURL = try #require(
      Bundle.module.url(
        forResource: "artifact-reference",
        withExtension: "json",
        subdirectory: "Fixtures"
      )
    )
    let fixtureData = try Data(contentsOf: fixtureURL)

    let reference = try JSONDecoder().decode(ArtifactReference.self, from: fixtureData)

    #expect(reference.id.digest.hexadecimalValue == String(repeating: "a", count: 64))
    #expect(reference.descriptor.role == .output)
    #expect(reference.descriptor.kind == .parasitics)
    #expect(reference.descriptor.format == .spef)
    #expect(reference.byteCount == 128)
  }

  @Test
  func artifactReferenceKeepsIdentityStableAcrossDescriptors() throws {
    let digest = try ContentDigest(
      algorithm: .sha256,
      hexadecimalValue: String(repeating: "a", count: 64)
    )

    let first = try ArtifactReference(
      digest: digest,
      byteCount: 42,
      descriptor: ArtifactDescriptor(role: .input, kind: .report, format: .json)
    )
    let second = try ArtifactReference(
      digest: digest,
      byteCount: 42,
      descriptor: ArtifactDescriptor(role: .output, kind: .evidence, format: .json)
    )

    #expect(first.id == second.id)
    #expect(first.descriptor != second.descriptor)
  }

  @Test
  func extensibleRawValuesUseSingleStringJSONRepresentation() throws {
    let encodedKind = try JSONEncoder().encode(ArtifactKind.report)
    let encodedFormat = try JSONEncoder().encode(ArtifactFormat.gdsii)

    #expect(String(decoding: encodedKind, as: UTF8.self) == "\"report\"")
    #expect(String(decoding: encodedFormat, as: UTF8.self) == "\"gdsii\"")
  }

  @Test
  func artifactIDRoundTripsCanonicalContentIdentity() throws {
    let digest = try ContentDigest(
      algorithm: .sha256,
      hexadecimalValue: String(repeating: "b", count: 64)
    )
    let identifier = try ArtifactID(digest: digest, byteCount: 91)
    let data = try JSONEncoder().encode(identifier)
    let decoded = try JSONDecoder().decode(ArtifactID.self, from: data)

    #expect(decoded == identifier)
    #expect(decoded.digest == digest)
    #expect(decoded.byteCount == 91)
  }

  @Test
  func artifactIDRejectsNonCanonicalEncoding() {
    #expect(throws: ArtifactIDError.invalidCanonicalEncoding) {
      try ArtifactID(canonicalHexadecimalValue: "not-hex")
    }
  }

  @Test
  func digestRejectsIncompleteHexadecimalByte() {
    #expect(throws: ContentDigestError.self) {
      try ContentDigest(
        algorithm: try ContentDigestAlgorithm(rawValue: "custom"),
        hexadecimalValue: "abc"
      )
    }
  }

  @Test
  func digestRejectsUnicodeHexadecimalCharacters() {
    #expect(throws: ContentDigestError.self) {
      try ContentDigest(
        algorithm: .sha256,
        hexadecimalValue: String(repeating: "Ａ", count: 64)
      )
    }
  }

  @Test
  func extensibleFoundationTokensRejectEmptyValues() {
    #expect(throws: TokenError.self) {
      try ArtifactKind(rawValue: "")
    }
    #expect(throws: TokenError.self) {
      try ArtifactFormat(rawValue: " json")
    }
    #expect(throws: TokenError.self) {
      try ContentDigestAlgorithm(rawValue: "\u{0000}")
    }
  }

  @Test
  func verifierReportsMissingArtifactAsStructuredIssue() throws {
    try withTemporaryDirectory { workspace in
      let location = try ArtifactLocation(workspaceRelativePath: "reports/missing.json")
      let locator = ArtifactLocator(location: location, role: .output, kind: .report, format: .json)
      let reference = try ArtifactReference(
        digest: try ContentDigest(
          algorithm: .sha256,
          hexadecimalValue: String(repeating: "0", count: 64)
        ),
        byteCount: 0,
        descriptor: locator.descriptor
      )

      let integrity = LocalArtifactVerifier(digester: SHA256ContentDigester())
        .verify(reference, at: locator, relativeTo: workspace)

      #expect(integrity.issues.map(\.code) == [.missingFile])
    }
  }

  @Test
  func verifierReportsByteCountMismatchSeparately() throws {
    try withTemporaryDirectory { workspace in
      let fileURL = workspace.appendingPathComponent("layout.gds")
      try Data([0x01, 0x02, 0x03]).write(to: fileURL)
      let digest = try SHA256ContentDigester().digest(fileAt: fileURL, using: .sha256)
      let location = try ArtifactLocation(workspaceRelativePath: "layout.gds")
      let locator = ArtifactLocator(location: location, role: .output, kind: .layout, format: .gdsii)
      let reference = try ArtifactReference(
        digest: digest,
        byteCount: 2,
        descriptor: locator.descriptor
      )

      let integrity = LocalArtifactVerifier(digester: SHA256ContentDigester())
        .verify(reference, at: locator, relativeTo: workspace)

      #expect(integrity.issues.map(\.code) == [.byteCountMismatch])
      #expect(integrity.issues.first?.expectedByteCount == 2)
      #expect(integrity.issues.first?.actualByteCount == 3)
    }
  }

  @Test
  func verifierReportsUnsupportedDigestAlgorithm() throws {
    try withTemporaryDirectory { workspace in
      let fileURL = workspace.appendingPathComponent("custom.bin")
      try Data([0x01]).write(to: fileURL)
      let location = try ArtifactLocation(workspaceRelativePath: "custom.bin")
      let algorithm = try ContentDigestAlgorithm(rawValue: "custom")
      let locator = ArtifactLocator(
        location: location,
        role: .output,
        kind: .evidence,
        format: try ArtifactFormat(rawValue: "binary")
      )
      let reference = try ArtifactReference(
        digest: try ContentDigest(algorithm: algorithm, hexadecimalValue: "00"),
        byteCount: 1,
        descriptor: locator.descriptor
      )

      let integrity = LocalArtifactVerifier(digester: SHA256ContentDigester())
        .verify(reference, at: locator, relativeTo: workspace)

      #expect(integrity.issues.map(\.code) == [.unsupportedDigestAlgorithm])
      #expect(integrity.issues.first?.digestAlgorithm == algorithm)
    }
  }

  private struct MutatingDigester: ContentDigesting {
    let fileURL: URL

    func digest(
      using algorithm: ContentDigestAlgorithm,
      limits: ContentDigestSessionLimits,
      _ body: (borrowing ContentDigestUpdateLease) throws(ContentDigestError) -> Void
    ) throws(ContentDigestError) -> ContentDigestResult {
      do {
        try Data("after".utf8).write(to: fileURL)
      } catch {
        throw .backendUpdateFailed(reason: error.localizedDescription)
      }
      return try SHA256ContentDigester().digest(
        using: algorithm,
        limits: limits,
        body
      )
    }

    func digest(data: Data, using algorithm: ContentDigestAlgorithm) throws -> ContentDigest {
      try SHA256ContentDigester().digest(data: data, using: algorithm)
    }

    func digest(fileAt url: URL, using algorithm: ContentDigestAlgorithm) throws -> ContentDigest {
      try Data("after".utf8).write(to: fileURL)
      return try SHA256ContentDigester().digest(data: Data("before".utf8), using: algorithm)
    }
  }

  private struct TestArtifactBytes: ArtifactOwnedBytes {
    let bytes: [UInt8]

    var byteCount: UInt64 {
      UInt64(bytes.count)
    }

    func withUnsafeBytes<Result>(
      _ body: (UnsafeRawBufferPointer) throws -> Result
    ) rethrows -> Result {
      try bytes.withUnsafeBytes(body)
    }
  }

  private func makeReference(
    path: String,
    digestByte: Character
  ) throws -> ArtifactReference {
    let digest = try ContentDigest(
      algorithm: .sha256,
      hexadecimalValue: String(repeating: digestByte, count: 64)
    )
    return try ArtifactReference(
      digest: digest,
      byteCount: 1,
      descriptor: ArtifactDescriptor(role: .output, kind: .report, format: .json)
    )
  }
}
