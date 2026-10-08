import CircuiteFoundation

struct SourceDiscoveryReader {
  static func discover(
    _ intent: ArtifactSourceDiscoveryIntent,
    rootDescriptor: Int32,
    digester: any ContentDigesting
  ) throws(ArtifactSourceDiscoveryError) -> ArtifactDiscoveredSource {
    let accounting = SourceDiscoveryAccounting(
      maximumDurationNanoseconds: intent.budget.maximumDurationNanoseconds
    )
    try accounting.check()
    let fixedWork = UInt64(intent.relativePath.segments.count) + 4
    guard fixedWork <= intent.budget.maximumWorkUnitCount else {
      throw .access(.workLimitExceeded(limit: intent.budget.maximumWorkUnitCount, requested: fixedWork))
    }
    let descriptor: Int32
    do {
      descriptor = try POSIXArtifactFile.openFile(
        relativePath: intent.relativePath, rootDescriptor: rootDescriptor
      )
    } catch { throw .access(ArtifactRootCapability.mapFileError(error)) }
    let source = try SourceDiscoveryAccounting.closing(descriptor) { () throws(ArtifactSourceDiscoveryError) in
      try observe(intent, descriptor: descriptor, digester: digester, accounting: accounting)
    }
    try accounting.check()
    return source.recordingElapsed(accounting.elapsedNanoseconds)
  }

  private static func observe(
    _ intent: ArtifactSourceDiscoveryIntent,
    descriptor: Int32,
    digester: any ContentDigesting,
    accounting: SourceDiscoveryAccounting
  ) throws(ArtifactSourceDiscoveryError) -> ArtifactDiscoveredSource {
    let initial: POSIXArtifactFileSnapshot
    do { initial = try POSIXArtifactFileSnapshot(fileDescriptor: descriptor) }
    catch { throw .access(ArtifactRootCapability.mapFileError(error)) }
    let budget = intent.budget
    guard initial.byteCount <= budget.maximumTotalByteCount,
          initial.byteCount <= UInt64(Int.max) else {
      throw .access(.totalByteLimitExceeded(
        limit: min(budget.maximumTotalByteCount, UInt64(Int.max)), requested: initial.byteCount
      ))
    }
    let chunkSize = min(budget.maximumPageByteCount, 1_048_576)
    let pageCount = initial.byteCount == 0 ? 0 : (initial.byteCount - 1) / chunkSize + 1
    guard pageCount <= budget.maximumPageCount else {
      throw .access(.pageCountLimitExceeded(limit: budget.maximumPageCount, requested: pageCount))
    }
    // One unit per traversal step, two metadata snapshots, root duplication and close,
    // plus one read and one digest update per admitted page.
    let fixedWork = UInt64(intent.relativePath.segments.count) + 4
    let requiredWork = pageCount.multipliedReportingOverflow(by: 2)
    let totalWork = requiredWork.partialValue.addingReportingOverflow(fixedWork)
    guard !requiredWork.overflow, !totalWork.overflow,
          totalWork.partialValue <= budget.maximumWorkUnitCount else {
      throw .access(.workLimitExceeded(limit: budget.maximumWorkUnitCount,
                                      requested: totalWork.overflow ? .max : totalWork.partialValue))
    }
    try accounting.check()
    var pages: [[UInt8]] = []
    let limits: ContentDigestSessionLimits
    do {
      limits = try ContentDigestSessionLimits(maximumChunkByteCount: chunkSize,
        maximumTotalByteCount: max(initial.byteCount, 1), maximumUpdateCount: max(pageCount, 1))
    } catch { throw .access(.readFailed(reason: String(describing: error))) }
    var observedByteCount: UInt64 = 0
    var primary: ArtifactSourceDiscoveryError?
    let result: ContentDigestResult
    do {
      result = try digester.digest(using: .sha256, limits: limits) {
        (lease: borrowing ContentDigestUpdateLease) throws(ContentDigestError) in
        while observedByteCount < initial.byteCount {
          do { try accounting.check() }
          catch let error as ArtifactSourceDiscoveryError {
            primary = error; throw .backendUpdateFailed(reason: String(describing: error))
          } catch { throw .backendUpdateFailed(reason: String(describing: error)) }
          let count = min(chunkSize, initial.byteCount - observedByteCount)
          let bytes: [UInt8]
          do { bytes = try POSIXArtifactFile.read(fileDescriptor: descriptor,
                                                offset: observedByteCount, byteCount: Int(count)) }
          catch {
            primary = .access(ArtifactRootCapability.mapFileError(error))
            throw .backendUpdateFailed(reason: String(describing: error))
          }
          try lease.update(bytes)
          pages.append(bytes)
          observedByteCount += count
        }
      }
    } catch {
      if let primary {
        if case .abortFailed(_, let abort) = error {
          throw .digestAbortFailed(primary: primary, abort: abort)
        }
        throw primary
      }
      throw .digest(error)
    }
    guard observedByteCount == initial.byteCount, UInt64(pages.count) == pageCount,
          result.totalByteCount == initial.byteCount, result.updateCount == pageCount,
          result.digest.algorithm == .sha256 else {
      throw .access(.readFailed(reason: "Digest accounting differs from observed source bytes."))
    }
    let final: POSIXArtifactFileSnapshot
    do { final = try POSIXArtifactFileSnapshot(fileDescriptor: descriptor) }
    catch { throw .access(ArtifactRootCapability.mapFileError(error)) }
    guard final == initial else { throw .access(.resourceGenerationChanged) }
    try accounting.check()
    let reference: ArtifactReference
    do {
      reference = try ArtifactReference(digest: result.digest, byteCount: result.totalByteCount,
                                       descriptor: intent.descriptor)
    } catch { throw .access(.readFailed(reason: String(describing: error))) }
    return ArtifactDiscoveredSource(reference: reference, pages: pages,
      work: ArtifactAccessWorkReport(pageCount: pageCount, workUnitCount: totalWork.partialValue,
                                     elapsedNanoseconds: accounting.elapsedNanoseconds))
  }
}
