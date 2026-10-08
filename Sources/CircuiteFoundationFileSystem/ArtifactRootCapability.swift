import CircuiteFoundation
import Foundation

public actor ArtifactRootCapability: ArtifactAccessing, ArtifactSourceDiscovering {
  public nonisolated let rootID: ArtifactRootID

  private let digester: any ContentDigesting
  private var rootDescriptor: Int32?
  private var acceptsNewSessions = true
  private var activeSessions: Set<ArtifactAccessSessionIdentity> = []
  private var drainWaiters: [CheckedContinuation<Void, Never>] = []
  private var termination: ArtifactRootCapabilityTermination?

  public init(
    rootID: ArtifactRootID,
    directoryURL: URL,
    digester: any ContentDigesting
  ) throws(ArtifactRootCapabilityError) {
    guard directoryURL.isFileURL, directoryURL.path.hasPrefix("/") else {
      throw .invalidRoot(reason: "The artifact root must be an absolute file URL.")
    }
    do {
      rootDescriptor = try POSIXArtifactFile.openRoot(at: directoryURL)
    } catch {
      throw .invalidRoot(reason: String(describing: error))
    }
    self.rootID = rootID
    self.digester = digester
  }

  public func open(
    _ intent: ArtifactAccessIntent
  ) async throws(ArtifactAccessError) -> any ArtifactReadSession {
    guard acceptsNewSessions, let rootDescriptor else {
      throw .sessionClosed
    }
    let relativePath: ArtifactRelativePath
    switch intent.availability {
    case .local(let artifactID, let selectedRootID, let selectedRelativePath):
      guard artifactID == intent.expectedReference.id else {
        throw .invalidIntent(
          .availabilityIdentityMismatch(
            expected: intent.expectedReference.id,
            actual: artifactID
          )
        )
      }
      guard selectedRootID == rootID else {
        throw .rootMismatch(expected: rootID, actual: selectedRootID)
      }
      relativePath = selectedRelativePath
    case .service:
      throw .availabilityNotLocal
    }

    let openedAt = Date()
    let fileDescriptor: Int32
    do {
      fileDescriptor = try POSIXArtifactFile.openFile(
        relativePath: relativePath,
        rootDescriptor: rootDescriptor
      )
    } catch {
      throw Self.mapFileError(error)
    }

    let preparation: PreparedRead
    do {
      preparation = try Self.prepareRead(
        fileDescriptor: fileDescriptor,
        expectedReference: intent.expectedReference,
        budget: intent.budget,
        digester: digester
      )
    } catch let primary as ArtifactAccessError {
      do {
        try POSIXArtifactFile.close(fileDescriptor)
      } catch let closeError {
        throw .cleanupFailed(
          primary: String(describing: primary),
          closeReason: String(describing: closeError)
        )
      }
      throw primary
    } catch let primary {
      do {
        try POSIXArtifactFile.close(fileDescriptor)
      } catch let closeError {
        throw .cleanupFailed(
          primary: String(describing: primary),
          closeReason: String(describing: closeError)
        )
      }
      throw .readFailed(reason: String(describing: primary))
    }

    let identity: ArtifactAccessSessionIdentity
    do {
      identity = try ArtifactAccessSessionIdentity(rawValue: UUID().uuidString)
    } catch let identityError {
      do {
        try POSIXArtifactFile.close(fileDescriptor)
      } catch let closeError {
        throw .cleanupFailed(
          primary: "Artifact access session identity creation failed: \(identityError)",
          closeReason: String(describing: closeError)
        )
      }
      throw .readFailed(reason: "Artifact access session identity creation failed: \(identityError)")
    }
    activeSessions.insert(identity)
    return ArtifactLocalReadSession(
      identity: identity,
      expectedReference: intent.expectedReference,
      fileDescriptor: fileDescriptor,
      initialSnapshot: preparation.snapshot,
      budget: intent.budget,
      openedAt: openedAt,
      digestWorkUnitCount: preparation.digestWorkUnitCount,
      releaseRootSession: { [self] identity in
        await releaseSession(identity)
      }
    )
  }

  public func discover(
    _ intent: ArtifactSourceDiscoveryIntent
  ) async throws(ArtifactSourceDiscoveryError) -> ArtifactDiscoveredSource {
    guard acceptsNewSessions, let rootDescriptor else { throw .access(.sessionClosed) }
    guard intent.rootID == rootID else {
      throw .access(.rootMismatch(expected: rootID, actual: intent.rootID))
    }
    // The synchronous operation cannot suspend this actor; close is admitted only after cleanup.
    return try SourceDiscoveryReader.discover(intent, rootDescriptor: rootDescriptor, digester: digester)
  }

  public func enumerate(
    _ intent: ArtifactDirectoryInventoryIntent
  ) async throws(ArtifactSourceDiscoveryError) -> ArtifactDirectoryInventory {
    guard acceptsNewSessions, let rootDescriptor else { throw .access(.sessionClosed) }
    guard intent.rootID == rootID else {
      throw .access(.rootMismatch(expected: rootID, actual: intent.rootID))
    }
    return try SourceDiscoveryInventory.enumerate(intent, rootDescriptor: rootDescriptor)
  }

  public func close() -> ArtifactRootCapabilityTermination {
    if let termination {
      return termination
    }
    acceptsNewSessions = false
    let task = Task { [self] in
      await finishClosing()
    }
    let stableTermination = ArtifactRootCapabilityTermination(task: task)
    termination = stableTermination
    return stableTermination
  }

  private func releaseSession(_ identity: ArtifactAccessSessionIdentity) {
    activeSessions.remove(identity)
    guard activeSessions.isEmpty else {
      return
    }
    let waiters = drainWaiters
    drainWaiters.removeAll(keepingCapacity: false)
    for waiter in waiters {
      waiter.resume()
    }
  }

  private func finishClosing() async -> Result<Void, ArtifactRootCapabilityError> {
    if !activeSessions.isEmpty {
      await withCheckedContinuation { continuation in
        drainWaiters.append(continuation)
      }
    }
    guard let descriptor = rootDescriptor else {
      return .success(())
    }
    rootDescriptor = nil
    do {
      try POSIXArtifactFile.close(descriptor)
      return .success(())
    } catch {
      return .failure(.closeFailed(reason: String(describing: error)))
    }
  }

  private struct PreparedRead {
    let snapshot: POSIXArtifactFileSnapshot
    let digestWorkUnitCount: UInt64
  }

  private static func prepareRead(
    fileDescriptor: Int32,
    expectedReference: ArtifactReference,
    budget: ArtifactAccessBudget,
    digester: any ContentDigesting
  ) throws -> PreparedRead {
    let initialSnapshot: POSIXArtifactFileSnapshot
    do {
      initialSnapshot = try POSIXArtifactFileSnapshot(fileDescriptor: fileDescriptor)
    } catch {
      throw mapFileError(error)
    }
    guard initialSnapshot.byteCount <= budget.maximumTotalByteCount else {
      throw ArtifactAccessError.totalByteLimitExceeded(
        limit: budget.maximumTotalByteCount,
        requested: initialSnapshot.byteCount
      )
    }
    guard initialSnapshot.byteCount == expectedReference.byteCount else {
      throw ArtifactAccessError.byteCountMismatch(
        expected: expectedReference.byteCount,
        actual: initialSnapshot.byteCount
      )
    }

    let chunkByteCount = min(budget.maximumPageByteCount, 1_048_576)
    let digestWorkUnitCount: UInt64
    if initialSnapshot.byteCount == 0 {
      digestWorkUnitCount = 0
    } else {
      let adjusted = initialSnapshot.byteCount - 1
      digestWorkUnitCount = adjusted / chunkByteCount + 1
    }
    guard digestWorkUnitCount <= budget.maximumWorkUnitCount else {
      throw ArtifactAccessError.workLimitExceeded(
        limit: budget.maximumWorkUnitCount,
        requested: digestWorkUnitCount
      )
    }

    let limits: ContentDigestSessionLimits
    do {
      limits = try ContentDigestSessionLimits(
        maximumChunkByteCount: chunkByteCount,
        maximumTotalByteCount: max(initialSnapshot.byteCount, 1),
        maximumUpdateCount: max(digestWorkUnitCount, 1)
      )
    } catch {
      throw ArtifactAccessError.readFailed(reason: String(describing: error))
    }

    let digestResult: ContentDigestResult
    do {
      digestResult = try digester.digest(
        using: expectedReference.digest.algorithm,
        limits: limits
      ) { (lease: borrowing ContentDigestUpdateLease) throws(ContentDigestError) in
        var offset: UInt64 = 0
        while offset < initialSnapshot.byteCount {
          if Task.isCancelled {
            throw .backendUpdateFailed(reason: "Artifact read was cancelled.")
          }
          let remaining = initialSnapshot.byteCount - offset
          let nextByteCount = min(chunkByteCount, remaining)
          guard nextByteCount <= UInt64(Int.max) else {
            throw .backendUpdateFailed(reason: "Digest chunk exceeds the platform Int range.")
          }
          let bytes: [UInt8]
          do {
            bytes = try POSIXArtifactFile.read(
              fileDescriptor: fileDescriptor,
              offset: offset,
              byteCount: Int(nextByteCount)
            )
          } catch {
            throw .backendUpdateFailed(reason: String(describing: error))
          }
          try lease.update(bytes)
          offset += nextByteCount
        }
      }
    } catch {
      if Task.isCancelled {
        throw ArtifactAccessError.cancelled
      }
      throw ArtifactAccessError.readFailed(reason: String(describing: error))
    }
    guard digestResult.digest == expectedReference.digest else {
      throw ArtifactAccessError.contentDigestMismatch(
        expected: expectedReference.digest,
        actual: digestResult.digest
      )
    }
    guard digestResult.totalByteCount == initialSnapshot.byteCount,
          digestResult.updateCount == digestWorkUnitCount else {
      throw ArtifactAccessError.readFailed(
        reason: "Digest accounting does not match the admitted file snapshot."
      )
    }

    let finalSnapshot: POSIXArtifactFileSnapshot
    do {
      finalSnapshot = try POSIXArtifactFileSnapshot(fileDescriptor: fileDescriptor)
    } catch {
      throw mapFileError(error)
    }
    guard finalSnapshot == initialSnapshot else {
      throw ArtifactAccessError.resourceGenerationChanged
    }
    return PreparedRead(
      snapshot: initialSnapshot,
      digestWorkUnitCount: digestWorkUnitCount
    )
  }

  static func mapFileError(_ error: any Error) -> ArtifactAccessError {
    switch error {
    case POSIXArtifactFileError.invalidRoot(let reason):
      return .invalidRoot(reason: reason)
    case POSIXArtifactFileError.metadataFailed(let reason):
      return .metadataFailed(reason: reason)
    case POSIXArtifactFileError.notRegularFile:
      return .nonRegularResource
    case POSIXArtifactFileError.invalidByteCount:
      return .metadataFailed(reason: "Artifact byte count is invalid.")
    case POSIXArtifactFileError.openFailed(let componentIndex, let reason):
      return .openFailed(componentIndex: componentIndex, reason: reason)
    case POSIXArtifactFileError.symlinkTraversal(let componentIndex):
      return .symlinkTraversal(componentIndex: componentIndex)
    case POSIXArtifactFileError.shortRead:
      return .truncatedResource
    case POSIXArtifactFileError.cleanupFailed(let primary, let closeReason):
      return .cleanupFailed(primary: primary, closeReason: closeReason)
    case POSIXArtifactFileError.closeFailed(let reason):
      return .fileCloseFailed(reason: reason)
    default:
      return .readFailed(reason: String(describing: error))
    }
  }
}
