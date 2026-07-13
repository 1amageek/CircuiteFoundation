import CircuiteFoundation
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
  func relativeLocationRejectsTraversal() {
    #expect(throws: ArtifactLocationError.self) {
      try ArtifactLocation(workspaceRelativePath: "reports/../outside.json")
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
      let locator = ArtifactLocator(location: location, kind: .report, format: .json)
      let reference = try LocalArtifactReferencer().reference(
        locator,
        relativeTo: workspace,
        producer: ProducerIdentity(
          kind: .engine,
          identifier: "TimingEngine",
          version: "1.0.0"
        )
      )

      #expect(reference.byteCount == 8)
      #expect(LocalArtifactVerifier().verify(reference, relativeTo: workspace).isVerified)

      try Data("modified".utf8).write(to: reportURL)
      let integrity = LocalArtifactVerifier().verify(reference, relativeTo: workspace)

      #expect(!integrity.isVerified)
      #expect(
        integrity.issues.contains { $0.code == .digestMismatch }
      )
    }
  }

  @Test
  func artifactReferenceRoundTripsThroughJSON() throws {
    let location = try ArtifactLocation(workspaceRelativePath: "pex/extracted.spef")
    let digest = try ContentDigest(
      algorithm: .sha256,
      hexadecimalValue: String(repeating: "a", count: 64)
    )
    let identifier = try #require(UUID(uuidString: "AF43165C-EC65-449D-868E-D26EB9C25A3F"))
    let reference = ArtifactReference(
      id: ArtifactID(rawValue: identifier),
      locator: ArtifactLocator(location: location, kind: .parasitics, format: .spef),
      digest: digest,
      byteCount: 128
    )

    let encoded = try JSONEncoder().encode(reference)
    let decoded = try JSONDecoder().decode(ArtifactReference.self, from: encoded)

    #expect(decoded == reference)
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

    #expect(reference.id.rawValue.uuidString == "AF43165C-EC65-449D-868E-D26EB9C25A3F")
    #expect(reference.locator.location.value == "pex/extracted.spef")
    #expect(reference.locator.kind == .parasitics)
    #expect(reference.locator.format == .spef)
    #expect(reference.byteCount == 128)
    #expect(reference.producer == nil)
  }

  @Test
  func extensibleRawValuesUseSingleStringJSONRepresentation() throws {
    let encodedKind = try JSONEncoder().encode(ArtifactKind.report)
    let encodedFormat = try JSONEncoder().encode(ArtifactFormat.gdsii)

    #expect(String(decoding: encodedKind, as: UTF8.self) == "\"report\"")
    #expect(String(decoding: encodedFormat, as: UTF8.self) == "\"gdsii\"")
  }

  @Test
  func digestRejectsIncompleteHexadecimalByte() {
    #expect(throws: ContentDigestError.self) {
      try ContentDigest(
        algorithm: ContentDigestAlgorithm(rawValue: "custom"),
        hexadecimalValue: "abc"
      )
    }
  }

  @Test
  func verifierReportsMissingArtifactAsStructuredIssue() throws {
    try withTemporaryDirectory { workspace in
      let location = try ArtifactLocation(workspaceRelativePath: "reports/missing.json")
      let reference = ArtifactReference(
        locator: ArtifactLocator(location: location, kind: .report, format: .json),
        digest: try ContentDigest(
          algorithm: .sha256,
          hexadecimalValue: String(repeating: "0", count: 64)
        ),
        byteCount: 0
      )

      let integrity = LocalArtifactVerifier().verify(reference, relativeTo: workspace)

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
      let reference = ArtifactReference(
        locator: ArtifactLocator(location: location, kind: .layout, format: .gdsii),
        digest: digest,
        byteCount: 2
      )

      let integrity = LocalArtifactVerifier().verify(reference, relativeTo: workspace)

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
      let algorithm = ContentDigestAlgorithm(rawValue: "custom")
      let reference = ArtifactReference(
        locator: ArtifactLocator(location: location, kind: .evidence, format: "binary"),
        digest: try ContentDigest(algorithm: algorithm, hexadecimalValue: "00"),
        byteCount: 1
      )

      let integrity = LocalArtifactVerifier().verify(reference, relativeTo: workspace)

      #expect(integrity.issues.map(\.code) == [.unsupportedDigestAlgorithm])
      #expect(integrity.issues.first?.digestAlgorithm == algorithm)
    }
  }
}
