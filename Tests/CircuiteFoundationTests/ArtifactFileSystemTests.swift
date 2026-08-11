import CircuiteFoundation
import CircuiteFoundationCrypto
import CircuiteFoundationFoundation
@testable import CircuiteFoundationFileSystem
import Foundation
import Testing

@Suite
struct ArtifactFileSystemTests {
  @Test
  func rootCapabilityReadsBoundedPagesAndDrainsBeforeClose() async throws {
    let workspace = try makeTemporaryDirectory()
    defer { removeTemporaryDirectory(workspace) }
    let reportURL = workspace.appendingPathComponent("report.json")
    try Data("accepted".utf8).write(to: reportURL)
    let reference = try makeReference(relativePath: "report.json", workspace: workspace)
    let rootID = try ArtifactRootID(rawValue: "test-root")
    let root = try ArtifactRootCapability(
      rootID: rootID,
      directoryURL: workspace,
      digester: SHA256ContentDigester()
    )
    let session = try await root.open(
      makeIntent(
        reference: reference,
        rootID: rootID,
        relativePath: try ArtifactRelativePath(segments: ["report.json"])
      )
    )

    let rootTermination = await root.close()
    let first = try await session.readPage(
      ArtifactReadPageRequest(offset: 0, maximumByteCount: 4)
    )
    let second = try await session.readPage(
      ArtifactReadPageRequest(offset: 4, maximumByteCount: 4)
    )

    #expect(first.completion == .more)
    #expect(readBytes(first) == Array("acce".utf8))
    #expect(second.completion == .complete)
    #expect(readBytes(second) == Array("pted".utf8))
    #expect(second.finalReceipt?.observedArtifactID == reference.id)

    let sessionTermination = await session.close()
    let sessionReceipt = try await sessionTermination.wait()
    #expect(sessionReceipt.didReachTerminalPage)
    try await rootTermination.wait()
  }

  @Test
  func rootCapabilityRejectsTamperedContent() async throws {
    let workspace = try makeTemporaryDirectory()
    defer { removeTemporaryDirectory(workspace) }
    let reportURL = workspace.appendingPathComponent("report.json")
    try Data("accepted".utf8).write(to: reportURL)
    let reference = try makeReference(relativePath: "report.json", workspace: workspace)
    try Data("modified".utf8).write(to: reportURL)
    let rootID = try ArtifactRootID(rawValue: "test-root")
    let root = try ArtifactRootCapability(
      rootID: rootID,
      directoryURL: workspace,
      digester: SHA256ContentDigester()
    )

    await #expect(throws: ArtifactAccessError.self) {
      _ = try await root.open(
        makeIntent(
          reference: reference,
          rootID: rootID,
          relativePath: try ArtifactRelativePath(segments: ["report.json"])
        )
      )
    }
    try await root.close().wait()
  }

  @Test
  func rootCapabilityRejectsSymlinkTraversal() async throws {
    let temporaryDirectory = try makeTemporaryDirectory()
    defer { removeTemporaryDirectory(temporaryDirectory) }
    let workspace = temporaryDirectory.appendingPathComponent("workspace", isDirectory: true)
    let outside = temporaryDirectory.appendingPathComponent("outside", isDirectory: true)
    try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    let outsideFile = outside.appendingPathComponent("evidence.json")
    let content = Data("outside".utf8)
    try content.write(to: outsideFile)
    try FileManager.default.createSymbolicLink(
      at: workspace.appendingPathComponent("linked.json"),
      withDestinationURL: outsideFile
    )
    let digest = try SHA256ContentDigester().digest(data: content)
    let reference = try ArtifactReference(
      digest: digest,
      byteCount: UInt64(content.count),
      descriptor: ArtifactDescriptor(role: .input, kind: .evidence, format: .json)
    )
    let rootID = try ArtifactRootID(rawValue: "test-root")
    let root = try ArtifactRootCapability(
      rootID: rootID,
      directoryURL: workspace,
      digester: SHA256ContentDigester()
    )

    await #expect(throws: ArtifactAccessError.symlinkTraversal(componentIndex: 0)) {
      _ = try await root.open(
        makeIntent(
          reference: reference,
          rootID: rootID,
          relativePath: try ArtifactRelativePath(segments: ["linked.json"])
        )
      )
    }
    try await root.close().wait()
  }

  @Test
  func artifactIdentityRemainsStableAfterRelocation() throws {
    let workspace = try makeTemporaryDirectory()
    defer { removeTemporaryDirectory(workspace) }
    let firstDirectory = workspace.appendingPathComponent("first", isDirectory: true)
    let secondDirectory = workspace.appendingPathComponent("second", isDirectory: true)
    try FileManager.default.createDirectory(at: firstDirectory, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: secondDirectory, withIntermediateDirectories: true)
    try Data("accepted".utf8).write(to: firstDirectory.appendingPathComponent("report.json"))
    try Data("accepted".utf8).write(to: secondDirectory.appendingPathComponent("renamed.json"))
    let referencer = LocalArtifactReferencer(digester: SHA256ContentDigester())

    let first = try referencer.reference(
      ArtifactLocator(
        location: ArtifactLocation(workspaceRelativePath: "first/report.json"),
        role: .output,
        kind: .report,
        format: .json
      ),
      relativeTo: workspace
    )
    let second = try referencer.reference(
      ArtifactLocator(
        location: ArtifactLocation(workspaceRelativePath: "second/renamed.json"),
        role: .output,
        kind: .report,
        format: .json
      ),
      relativeTo: workspace
    )

    #expect(first == second)
    #expect(first.id == second.id)
  }

  @Test
  func rootCapabilityRejectsSymlinkSwapAfterOpen() async throws {
    let workspace = try makeTemporaryDirectory()
    defer { removeTemporaryDirectory(workspace) }
    let reportURL = workspace.appendingPathComponent("report.json")
    let outsideURL = workspace.appendingPathComponent("outside.json")
    try Data("accepted".utf8).write(to: reportURL)
    try Data("redirected".utf8).write(to: outsideURL)
    let reference = try makeReference(relativePath: "report.json", workspace: workspace)
    let rootID = try ArtifactRootID(rawValue: "test-root")
    let root = try ArtifactRootCapability(
      rootID: rootID,
      directoryURL: workspace,
      digester: SymlinkReplacingDigester(fileURL: reportURL, replacementURL: outsideURL)
    )

    await #expect(throws: ArtifactAccessError.resourceGenerationChanged) {
      _ = try await root.open(
        makeIntent(
          reference: reference,
          rootID: rootID,
          relativePath: try ArtifactRelativePath(segments: ["report.json"])
        )
      )
    }
    try await root.close().wait()
  }

  @Test
  func rootCapabilityRejectsArtifactBeyondTotalByteBudget() async throws {
    let workspace = try makeTemporaryDirectory()
    defer { removeTemporaryDirectory(workspace) }
    let reportURL = workspace.appendingPathComponent("report.json")
    try Data("accepted".utf8).write(to: reportURL)
    let reference = try makeReference(relativePath: "report.json", workspace: workspace)
    let rootID = try ArtifactRootID(rawValue: "test-root")
    let root = try ArtifactRootCapability(
      rootID: rootID,
      directoryURL: workspace,
      digester: SHA256ContentDigester()
    )
    let intent = try ArtifactAccessIntent(
      expectedReference: reference,
      availability: .local(
        artifactID: reference.id,
        rootID: rootID,
        relativePath: ArtifactRelativePath(segments: ["report.json"])
      ),
      operation: .read,
      budget: ArtifactAccessBudget(
        maximumPageByteCount: 4,
        maximumTotalByteCount: 4,
        maximumPageCount: 1,
        maximumWorkUnitCount: 1,
        maximumDurationNanoseconds: 5_000_000_000
      )
    )

    await #expect(throws: ArtifactAccessError.totalByteLimitExceeded(limit: 4, requested: 8)) {
      _ = try await root.open(intent)
    }
    try await root.close().wait()
  }

  @Test
  func accessTerminationPreservesCloseFailure() async throws {
    let identity = try ArtifactAccessSessionIdentity(rawValue: "close-failure")
    let termination = ArtifactLocalAccessTermination(
      sessionIdentity: identity,
      didReachTerminalPage: false,
      closeErrorReason: "simulated close failure"
    )

    await #expect(
      throws: ArtifactAccessTerminationError.cleanupFailed(reason: "simulated close failure")
    ) {
      _ = try await termination.wait()
    }
  }

  private func makeReference(
    relativePath: String,
    workspace: URL
  ) throws -> ArtifactReference {
    try LocalArtifactReferencer(digester: SHA256ContentDigester()).reference(
      ArtifactLocator(
        location: ArtifactLocation(workspaceRelativePath: relativePath),
        role: .output,
        kind: .report,
        format: .json
      ),
      relativeTo: workspace
    )
  }

  private func makeIntent(
    reference: ArtifactReference,
    rootID: ArtifactRootID,
    relativePath: ArtifactRelativePath
  ) throws -> ArtifactAccessIntent {
    try ArtifactAccessIntent(
      expectedReference: reference,
      availability: .local(
        artifactID: reference.id,
        rootID: rootID,
        relativePath: relativePath
      ),
      operation: .read,
      budget: ArtifactAccessBudget(
        maximumPageByteCount: 4,
        maximumTotalByteCount: 64,
        maximumPageCount: 16,
        maximumWorkUnitCount: 32,
        maximumDurationNanoseconds: 5_000_000_000
      )
    )
  }

  private func readBytes(_ page: ArtifactReadPage) -> [UInt8] {
    page.bytes.withUnsafeBytes { buffer in
      Array(buffer)
    }
  }

  private func makeTemporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  private func removeTemporaryDirectory(_ directory: URL) {
    do {
      try FileManager.default.removeItem(at: directory)
    } catch {
      Issue.record("Temporary directory cleanup failed: \(error)")
    }
  }

  private struct SymlinkReplacingDigester: ContentDigesting {
    let fileURL: URL
    let replacementURL: URL

    func digest(
      using algorithm: ContentDigestAlgorithm,
      limits: ContentDigestSessionLimits,
      _ body: (borrowing ContentDigestUpdateLease) throws(ContentDigestError) -> Void
    ) throws(ContentDigestError) -> ContentDigestResult {
      do {
        try FileManager.default.removeItem(at: fileURL)
        try FileManager.default.createSymbolicLink(at: fileURL, withDestinationURL: replacementURL)
      } catch {
        throw .backendUpdateFailed(reason: String(describing: error))
      }
      return try SHA256ContentDigester().digest(
        using: algorithm,
        limits: limits,
        body
      )
    }
  }
}
