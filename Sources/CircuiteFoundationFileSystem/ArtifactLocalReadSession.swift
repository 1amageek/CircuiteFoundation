import CircuiteFoundation
import Foundation

actor ArtifactLocalReadSession: ArtifactReadSession {
  nonisolated let identity: ArtifactAccessSessionIdentity
  nonisolated let expectedReference: ArtifactReference

  private let fileDescriptor: Int32
  private let initialSnapshot: POSIXArtifactFileSnapshot
  private let budget: ArtifactAccessBudget
  private let openedAt: Date
  private let digestWorkUnitCount: UInt64
  private let releaseRootSession: @Sendable (ArtifactAccessSessionIdentity) async -> Void

  private var nextOffset: UInt64 = 0
  private var pageCount: UInt64 = 0
  private var workUnitCount: UInt64
  private var termination: (any ArtifactAccessTermination)?

  init(
    identity: ArtifactAccessSessionIdentity,
    expectedReference: ArtifactReference,
    fileDescriptor: Int32,
    initialSnapshot: POSIXArtifactFileSnapshot,
    budget: ArtifactAccessBudget,
    openedAt: Date,
    digestWorkUnitCount: UInt64,
    releaseRootSession: @escaping @Sendable (ArtifactAccessSessionIdentity) async -> Void
  ) {
    self.identity = identity
    self.expectedReference = expectedReference
    self.fileDescriptor = fileDescriptor
    self.initialSnapshot = initialSnapshot
    self.budget = budget
    self.openedAt = openedAt
    self.digestWorkUnitCount = digestWorkUnitCount
    self.workUnitCount = digestWorkUnitCount
    self.releaseRootSession = releaseRootSession
  }

  func readPage(
    _ request: ArtifactReadPageRequest
  ) async throws(ArtifactAccessError) -> ArtifactReadPage {
    guard termination == nil else {
      throw .sessionClosed
    }
    try validateDeadline()
    guard request.offset == nextOffset else {
      throw .noncontiguousOffset(expected: nextOffset, actual: request.offset)
    }
    guard request.maximumByteCount <= budget.maximumPageByteCount else {
      throw .pageByteLimitExceeded(
        limit: budget.maximumPageByteCount,
        requested: request.maximumByteCount
      )
    }
    let (nextPageCount, pageOverflow) = pageCount.addingReportingOverflow(1)
    guard !pageOverflow, nextPageCount <= budget.maximumPageCount else {
      throw .pageCountLimitExceeded(limit: budget.maximumPageCount, requested: UInt64.max)
    }
    let (nextWorkUnitCount, workOverflow) = workUnitCount.addingReportingOverflow(1)
    guard !workOverflow, nextWorkUnitCount <= budget.maximumWorkUnitCount else {
      throw .workLimitExceeded(limit: budget.maximumWorkUnitCount, requested: UInt64.max)
    }

    let remainingByteCount = initialSnapshot.byteCount - nextOffset
    let requestedByteCount = min(request.maximumByteCount, remainingByteCount)
    guard requestedByteCount <= UInt64(Int.max) else {
      throw .readFailed(reason: "Requested page exceeds the platform Int range.")
    }
    let bytes: [UInt8]
    do {
      bytes = try POSIXArtifactFile.read(
        fileDescriptor: fileDescriptor,
        offset: nextOffset,
        byteCount: Int(requestedByteCount)
      )
    } catch {
      throw Self.mapFileError(error)
    }

    let (pageEnd, offsetOverflow) = nextOffset.addingReportingOverflow(requestedByteCount)
    guard !offsetOverflow else {
      throw .readFailed(reason: "Artifact page offset overflowed.")
    }
    nextOffset = pageEnd
    pageCount = nextPageCount
    workUnitCount = nextWorkUnitCount
    let didComplete = nextOffset == initialSnapshot.byteCount
    let elapsedNanoseconds = elapsedNanosecondsSinceOpen()
    let work = ArtifactAccessWorkReport(
      pageCount: pageCount,
      workUnitCount: workUnitCount,
      elapsedNanoseconds: elapsedNanoseconds
    )

    if didComplete {
      let finalSnapshot: POSIXArtifactFileSnapshot
      do {
        finalSnapshot = try POSIXArtifactFileSnapshot(fileDescriptor: fileDescriptor)
      } catch {
        throw Self.mapFileError(error)
      }
      guard finalSnapshot == initialSnapshot else {
        throw .resourceGenerationChanged
      }
      let receipt = ArtifactAccessReceipt(
        observedArtifactID: expectedReference.id,
        totalByteCount: nextOffset,
        cumulativeWork: work
      )
      let page: ArtifactReadPage
      do {
        page = try ArtifactReadPage(
          offset: request.offset,
          bytes: ArtifactLocalOwnedBytes(storage: bytes),
          cumulativeByteCount: nextOffset,
          cumulativeWork: work,
          completion: .complete,
          finalReceipt: receipt
        )
      } catch {
        throw .readFailed(reason: "Invalid terminal page state: \(error)")
      }
      _ = await finishClose(didReachTerminalPage: true)
      return page
    }

    do {
      return try ArtifactReadPage(
        offset: request.offset,
        bytes: ArtifactLocalOwnedBytes(storage: bytes),
        cumulativeByteCount: nextOffset,
        cumulativeWork: work,
        completion: .more,
        finalReceipt: nil
      )
    } catch {
      throw .readFailed(reason: "Invalid nonterminal page state: \(error)")
    }
  }

  func close() async -> any ArtifactAccessTermination {
    await finishClose(didReachTerminalPage: false)
  }

  private func finishClose(
    didReachTerminalPage: Bool
  ) async -> any ArtifactAccessTermination {
    if let termination {
      return termination
    }
    let closeErrorReason: String?
    do {
      try POSIXArtifactFile.close(fileDescriptor)
      closeErrorReason = nil
    } catch {
      closeErrorReason = String(describing: error)
    }
    let stableTermination = ArtifactLocalAccessTermination(
      sessionIdentity: identity,
      didReachTerminalPage: didReachTerminalPage,
      closeErrorReason: closeErrorReason
    )
    termination = stableTermination
    await releaseRootSession(identity)
    return stableTermination
  }

  private func validateDeadline() throws(ArtifactAccessError) {
    guard elapsedNanosecondsSinceOpen() <= budget.maximumDurationNanoseconds else {
      throw .deadlineExceeded
    }
  }

  private func elapsedNanosecondsSinceOpen() -> UInt64 {
    let seconds = Date().timeIntervalSince(openedAt)
    guard seconds.isFinite, seconds > 0 else {
      return 0
    }
    let nanoseconds = seconds * 1_000_000_000
    guard nanoseconds < Double(UInt64.max) else {
      return UInt64.max
    }
    return UInt64(nanoseconds.rounded(.up))
  }

  private static func mapFileError(_ error: any Error) -> ArtifactAccessError {
    switch error {
    case POSIXArtifactFileError.notRegularFile:
      return .nonRegularResource
    case POSIXArtifactFileError.metadataFailed(let reason):
      return .metadataFailed(reason: reason)
    case POSIXArtifactFileError.readFailed(let reason):
      return .readFailed(reason: reason)
    case POSIXArtifactFileError.shortRead(let expected, let actual):
      return .readFailed(reason: "Short read: expected \(expected) bytes, received \(actual).")
    case POSIXArtifactFileError.offsetOverflow:
      return .readFailed(reason: "Artifact read offset exceeds the platform range.")
    default:
      return .readFailed(reason: String(describing: error))
    }
  }
}
