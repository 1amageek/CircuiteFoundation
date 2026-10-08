import CircuiteFoundation
import CircuiteFoundationCrypto
import CircuiteFoundationFoundation
@testable import CircuiteFoundationFileSystem
import Darwin
import Foundation
import Synchronization
import Testing

@Suite(.timeLimit(.minutes(1)))
struct ArtifactSourceDiscoveryTests {
  @Test
  func observedBytesIdentityAndEmptyInputRemainOwnedAfterRootClose() async throws {
    let directory = try temporaryDirectory()
    defer { remove(directory) }
    let bytes = Data("bounded immutable content".utf8)
    try bytes.write(to: directory.appendingPathComponent("input"))
    try Data().write(to: directory.appendingPathComponent("empty"))
    let root = try makeRoot(directory)
    let discoverer: any ArtifactSourceDiscovering = root
    let source = try await discoverer.discover(discovery("input"))
    let empty = try await discoverer.discover(discovery("empty"))
    try await root.close().wait()
    #expect(source.reference.digest == (try SHA256ContentDigester().digest(data: bytes)))
    #expect(source.byteCount == UInt64(bytes.count))
    #expect(source.work.pageCount == 7)
    #expect(source.work.workUnitCount == 19)
    #expect(source.withUnsafeBytes { Array($0) } == Array(bytes))
    var pages: [UInt8] = []
    source.withUnsafeBytePages { pages.append(contentsOf: $0) }
    #expect(pages == Array(bytes))
    #expect(empty.reference.digest == (try SHA256ContentDigester().digest(data: Data())))
    #expect(empty.byteCount == 0)
    #expect(empty.withUnsafeBytes { $0.isEmpty })
    await #expect(throws: ArtifactSourceDiscoveryError.access(.sessionClosed)) {
      _ = try await root.discover(discovery("input"))
    }
  }

  @Test
  func rootAndPathSecurityRejectMismatchSymlinksAndNonregularFiles() async throws {
    let directory = try temporaryDirectory()
    defer { remove(directory) }
    try Data("outside".utf8).write(to: directory.appendingPathComponent("target"))
    try FileManager.default.createSymbolicLink(atPath: directory.appendingPathComponent("link").path,
                                             withDestinationPath: "target")
    try FileManager.default.createSymbolicLink(atPath: directory.appendingPathComponent("nested").path,
                                             withDestinationPath: directory.path)
    let fifo = directory.appendingPathComponent("fifo").path
    #expect(fifo.withCString { mkfifo($0, 0o600) } == 0)
    let root = try makeRoot(directory)
    await #expect(throws: ArtifactSourceDiscoveryError.access(.symlinkTraversal(componentIndex: 0))) {
      _ = try await root.discover(discovery("link"))
    }
    await #expect(throws: ArtifactSourceDiscoveryError.self) {
      _ = try await root.discover(discovery("nested/target"))
    }
    await #expect(throws: ArtifactSourceDiscoveryError.access(.nonRegularResource)) {
      _ = try await root.discover(discovery("fifo"))
    }
    let wrongID = try ArtifactRootID(rawValue: "wrong-root")
    let wrongIntent = try ArtifactSourceDiscoveryIntent(rootID: wrongID,
      relativePath: .init(segments: ["target"]), descriptor: descriptor, budget: budget())
    await #expect(throws: ArtifactSourceDiscoveryError.access(
      .rootMismatch(expected: try rootID, actual: wrongID))) {
      _ = try await root.discover(wrongIntent)
    }
    #expect(throws: ArtifactRelativePathError.self) { try ArtifactRelativePath(segments: ["..", "target"]) }
    try await root.close().wait()
  }

  @Test(arguments: [Mutation.grow, .truncate, .sameLength, .symlink])
  func rejectsSourceMutationDuringObservation(_ mutation: Mutation) async throws {
    let directory = try temporaryDirectory()
    defer { remove(directory) }
    let file = directory.appendingPathComponent("input")
    try Data("original".utf8).write(to: file)
    let root = try makeRoot(directory, digester: ChangingDigester(file: file, mutation: mutation))
    await #expect(throws: ArtifactSourceDiscoveryError.access(.resourceGenerationChanged)) {
      _ = try await root.discover(discovery("input"))
    }
    try await root.close().wait()
  }

  @Test
  func truncationDuringReadAndLateSuccessHaveDistinctFailures() async throws {
    let directory = try temporaryDirectory()
    defer { remove(directory) }
    let file = directory.appendingPathComponent("input")
    try Data("original".utf8).write(to: file)
    let truncated = try makeRoot(directory,
      digester: BeforeReadDigester(file: file, delay: false))
    await #expect(throws: ArtifactSourceDiscoveryError.access(.truncatedResource)) {
      _ = try await truncated.discover(discovery("input"))
    }
    try await truncated.close().wait()
    try Data("original".utf8).write(to: file)
    let delayed = try makeRoot(directory,
      digester: BeforeReadDigester(file: file, delay: true))
    do {
      _ = try await delayed.discover(discovery("input", limits: budget(duration: 1_000_000)))
      Issue.record("Late source observation returned success.")
    } catch let error as ArtifactSourceDiscoveryError {
      guard case .deadlineExceeded = error else { throw error }
    }
    try await delayed.close().wait()
  }

  @Test
  func budgetsAreRejectedBeforeDigestOrAllocation() async throws {
    let directory = try temporaryDirectory()
    defer { remove(directory) }
    try Data("12345678".utf8).write(to: directory.appendingPathComponent("input"))
    let root = try makeRoot(directory, digester: RejectingDigester())
    await #expect(throws: ArtifactSourceDiscoveryError.access(
      .totalByteLimitExceeded(limit: 4, requested: 8))) {
      _ = try await root.discover(discovery("input", limits: budget(total: 4)))
    }
    await #expect(throws: ArtifactSourceDiscoveryError.access(
      .pageCountLimitExceeded(limit: 1, requested: 2))) {
      _ = try await root.discover(discovery("input", limits: budget(pages: 1)))
    }
    await #expect(throws: ArtifactSourceDiscoveryError.access(
      .workLimitExceeded(limit: 8, requested: 9))) {
      _ = try await root.discover(discovery("input", limits: budget(work: 8)))
    }
    await #expect(throws: ArtifactSourceDiscoveryError.self) {
      _ = try await root.discover(discovery("input", limits: budget(duration: 1)))
    }
    try await root.close().wait()
  }

  @Test
  func enumerationIsDeterministicAndCountsRejectedNamesWithoutFollowingLinks() async throws {
    let directory = try temporaryDirectory()
    defer { remove(directory) }
    try FileManager.default.createDirectory(at: directory.appendingPathComponent("sub"),
                                            withIntermediateDirectories: false)
    try Data("a".utf8).write(to: directory.appendingPathComponent("z"))
    try Data("b".utf8).write(to: directory.appendingPathComponent("sub/a"))
    try FileManager.default.createSymbolicLink(atPath: directory.appendingPathComponent("link").path,
                                             withDestinationPath: directory.path)
    // Darwin permits filenames that Core deliberately refuses to represent.
    let badName = directory.path + "/bad\nname"
    let badFD = badName.withCString { Darwin.open($0, O_CREAT | O_WRONLY | O_CLOEXEC, 0o600) }
    #expect(badFD >= 0)
    try POSIXArtifactFile.close(badFD)
    let root = try makeRoot(directory)
    let first = try await root.enumerate(inventory())
    let second = try await root.enumerate(inventory())
    #expect(first.entries == second.entries)
    #expect(first.entries.map { $0.relativePath.segments.joined(separator: "/") }
      == ["link", "sub", "sub/a", "z"])
    #expect(first.entries.first?.kind == .symbolicLink)
    #expect(first.progress.visitedEntryCount == 9) // Four dot entries + five names.
    #expect(first.progress.resultCount == 4)
    #expect(first.work.workUnitCount > first.progress.visitedEntryCount)
    do {
      _ = try await root.enumerate(inventory(work: first.work.workUnitCount - 1))
      Issue.record("Sorting work was not charged.")
    } catch let error as ArtifactSourceDiscoveryError {
      guard case .workLimitExceeded(_, let progress) = error else { throw error }
      #expect(progress.visitedEntryCount == first.progress.visitedEntryCount)
      #expect(progress.resultCount == first.progress.resultCount)
    }
    let start = try ArtifactDirectoryInventoryIntent(rootID: rootID,
      start: .init(segments: ["sub"]), maximumVisitedEntryCount: 10, maximumDepth: 1,
      maximumResultCount: 10, maximumWorkUnitCount: 1_000,
      maximumDurationNanoseconds: 5_000_000_000)
    #expect(try await root.enumerate(start).entries.map { $0.relativePath.segments } == [["sub", "a"]])
    try await root.close().wait()
  }

  @Test
  func inventoryBoundariesIncludePartialProgressAndNeverReturnCompleteResults() async throws {
    let directory = try temporaryDirectory()
    defer { remove(directory) }
    try FileManager.default.createDirectory(at: directory.appendingPathComponent("sub/deeper"),
                                            withIntermediateDirectories: true)
    try Data().write(to: directory.appendingPathComponent("a"))
    let root = try makeRoot(directory)
    do {
      _ = try await root.enumerate(inventory(visited: 1))
      Issue.record("Visited-entry bound was ignored.")
    } catch let error as ArtifactSourceDiscoveryError {
      guard case .entryLimitExceeded(let limit, let progress) = error else { throw error }
      #expect(limit == 1)
      #expect(progress.visitedEntryCount == 2)
    }
    await #expect(throws: ArtifactSourceDiscoveryError.self) {
      _ = try await root.enumerate(inventory(depth: 1))
    }
    await #expect(throws: ArtifactSourceDiscoveryError.self) {
      _ = try await root.enumerate(inventory(results: 1))
    }
    await #expect(throws: ArtifactSourceDiscoveryError.self) {
      _ = try await root.enumerate(inventory(work: 1))
    }
    await #expect(throws: ArtifactSourceDiscoveryError.self) {
      _ = try await root.enumerate(inventory(duration: 1))
    }
    #expect(throws: ArtifactSourceDiscoveryError.invalidInventoryLimits) { try inventory(visited: 0) }
    // Failure closes all directory streams; a later complete operation remains usable.
    #expect(try await root.enumerate(inventory()).entries.count == 3)
    try await root.close().wait()
  }

  @available(macOS 15.0, *)
  @Test
  func cancellationAndQueuedRootCloseDrainAnInFlightSource() async throws {
    let directory = try temporaryDirectory()
    defer { remove(directory) }
    try Data("12345678".utf8).write(to: directory.appendingPathComponent("input"))
    let gate = DiscoveryReadGate()
    defer { gate.release() }
    let root = try makeRoot(directory, digester: GatedDigester(gate: gate))
    let intent = try discovery("input")
    let operation = Task { try await root.discover(intent) }
    while !gate.entered { try await Task.sleep(for: .milliseconds(1)) }
    let closing = Task { try await root.close().wait() }
    operation.cancel()
    gate.release()
    do { _ = try await operation.value; Issue.record("Cancelled source returned success.") }
    catch let error as ArtifactSourceDiscoveryError {
      guard case .cancelled = error else { throw error }
    }
    try await closing.value
    await #expect(throws: ArtifactSourceDiscoveryError.access(.sessionClosed)) {
      _ = try await root.enumerate(inventory())
    }
  }

  @Test
  func inventoryCancellationClosesBeforeReturning() async throws {
    let directory = try temporaryDirectory()
    defer { remove(directory) }
    let root = try makeRoot(directory)
    let intent = try inventory()
    let operation = Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return try await root.enumerate(intent)
    }
    do { _ = try await operation.value; Issue.record("Cancelled inventory returned success.") }
    catch let error as ArtifactSourceDiscoveryError {
      guard case .cancelled(let progress) = error else { throw error }
      #expect(progress.visitedEntryCount == 0)
    }
    try await root.close().wait()
  }

  @Test
  func cleanupPreservesTypedPrimaryAndCloseFailure() throws {
    let primary = ArtifactSourceDiscoveryError.access(.truncatedResource)
    let expected = ArtifactSourceDiscoveryError.cleanupFailed(primary: primary, closeReason: "close")
    #expect(throws: expected) {
      _ = try SourceDiscoveryAccounting.closing(0, close: { _ in throw TestCloseError.close }) {
        () throws(ArtifactSourceDiscoveryError) in throw primary
      }
    }
    #expect(throws: ArtifactSourceDiscoveryError.cleanupFailed(primary: nil, closeReason: "close")) {
      try SourceDiscoveryAccounting.closing(0, close: { _ in throw TestCloseError.close }) {
        () throws(ArtifactSourceDiscoveryError) in ()
      }
    }
  }

  enum Mutation: Sendable { case grow, truncate, sameLength, symlink }
  enum TestCloseError: Error { case close }
  private var rootID: ArtifactRootID { get throws { try .init(rawValue: "source-test") } }
  private var descriptor: ArtifactDescriptor { .init(role: .input, kind: .evidence, format: .json) }

  private func makeRoot(_ directory: URL, digester: any ContentDigesting = SHA256ContentDigester())
    throws -> ArtifactRootCapability {
    try .init(rootID: rootID, directoryURL: directory, digester: digester)
  }
  private func discovery(_ path: String, limits: ArtifactAccessBudget? = nil)
    throws -> ArtifactSourceDiscoveryIntent {
    try .init(rootID: rootID, relativePath: .init(segments: path.split(separator: "/").map(String.init)),
              descriptor: descriptor, budget: limits ?? budget())
  }
  private func budget(total: UInt64 = 1_024, pages: UInt64 = 256, work: UInt64 = 1_024,
                      duration: UInt64 = 5_000_000_000) throws -> ArtifactAccessBudget {
    try .init(maximumPageByteCount: 4, maximumTotalByteCount: total,
              maximumPageCount: pages, maximumWorkUnitCount: work,
              maximumDurationNanoseconds: duration)
  }
  private func inventory(visited: UInt64 = 100, depth: UInt64 = 8, results: UInt64 = 100,
                         work: UInt64 = 10_000, duration: UInt64 = 5_000_000_000)
    throws -> ArtifactDirectoryInventoryIntent {
    try .init(rootID: rootID, maximumVisitedEntryCount: visited, maximumDepth: depth,
              maximumResultCount: results, maximumWorkUnitCount: work,
              maximumDurationNanoseconds: duration)
  }
  private func temporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
    return directory
  }
  private func remove(_ directory: URL) {
    do { try FileManager.default.removeItem(at: directory) }
    catch { Issue.record("Temporary directory cleanup failed: \(error)") }
  }
}

private struct ChangingDigester: ContentDigesting {
  let file: URL
  let mutation: ArtifactSourceDiscoveryTests.Mutation
  func digest(using algorithm: ContentDigestAlgorithm, limits: ContentDigestSessionLimits,
              _ body: (borrowing ContentDigestUpdateLease) throws(ContentDigestError) -> Void)
    throws(ContentDigestError) -> ContentDigestResult {
    let result = try SHA256ContentDigester().digest(using: algorithm, limits: limits, body)
    do {
      switch mutation {
      case .grow: try Data("original grows".utf8).write(to: file)
      case .truncate: try Data("short".utf8).write(to: file)
      case .sameLength:
        let handle = try FileHandle(forWritingTo: file)
        do { try handle.write(contentsOf: Data("modified".utf8)); try handle.close() }
        catch { try handle.close(); throw error }
      case .symlink:
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createSymbolicLink(atPath: file.path, withDestinationPath: "/etc/hosts")
      }
    } catch { throw .backendUpdateFailed(reason: String(describing: error)) }
    return result
  }
}

private struct RejectingDigester: ContentDigesting {
  func digest(using algorithm: ContentDigestAlgorithm, limits: ContentDigestSessionLimits,
              _ body: (borrowing ContentDigestUpdateLease) throws(ContentDigestError) -> Void)
    throws(ContentDigestError) -> ContentDigestResult {
    throw .backendUnavailable(reason: "Digest must not start when admission fails.")
  }
}

@available(macOS 15.0, *)
private final class DiscoveryReadGate: Sendable {
  private struct State { var entered = false; var released = false }
  private let state = Mutex(State())
  var entered: Bool { state.withLock { $0.entered } }
  func release() { state.withLock { $0.released = true } }
  func wait() {
    state.withLock { $0.entered = true }
    while !state.withLock({ $0.released }) { Thread.sleep(forTimeInterval: 0.001) }
  }
}

@available(macOS 15.0, *)
private struct GatedDigester: ContentDigesting {
  let gate: DiscoveryReadGate
  func digest(using algorithm: ContentDigestAlgorithm, limits: ContentDigestSessionLimits,
              _ body: (borrowing ContentDigestUpdateLease) throws(ContentDigestError) -> Void)
    throws(ContentDigestError) -> ContentDigestResult {
    gate.wait()
    return try SHA256ContentDigester().digest(using: algorithm, limits: limits, body)
  }
}

private struct BeforeReadDigester: ContentDigesting {
  let file: URL
  let delay: Bool
  func digest(using algorithm: ContentDigestAlgorithm, limits: ContentDigestSessionLimits,
              _ body: (borrowing ContentDigestUpdateLease) throws(ContentDigestError) -> Void)
    throws(ContentDigestError) -> ContentDigestResult {
    if delay { Thread.sleep(forTimeInterval: 0.003) }
    else {
      do { try Data("x".utf8).write(to: file) }
      catch { throw .backendUpdateFailed(reason: String(describing: error)) }
    }
    return try SHA256ContentDigester().digest(using: algorithm, limits: limits, body)
  }
}
