package final class ContentDigestSessionState {
  private enum Lifecycle {
    case active
    case finalizing
    case finished
    case aborted
  }

  private let backend: any ContentDigestSessionBackend
  private let limits: ContentDigestSessionLimits
  private var lifecycle = Lifecycle.active
  private var totalByteCount: UInt64 = 0
  private var updateCount: UInt64 = 0

  package init(
    backend: any ContentDigestSessionBackend,
    limits: ContentDigestSessionLimits
  ) {
    self.backend = backend
    self.limits = limits
  }

  package func update(
    _ bytes: borrowing [UInt8]
  ) throws(ContentDigestError) {
    guard lifecycle == .active else {
      throw .sessionStateViolation
    }
    guard let requestedByteCount = UInt64(exactly: bytes.count) else {
      throw .byteCountOverflow
    }
    guard requestedByteCount <= limits.maximumChunkByteCount else {
      throw .chunkByteLimitExceeded(
        limit: limits.maximumChunkByteCount,
        requested: requestedByteCount
      )
    }
    let (nextTotalByteCount, byteOverflow) = totalByteCount.addingReportingOverflow(requestedByteCount)
    guard !byteOverflow else {
      throw .byteCountOverflow
    }
    guard nextTotalByteCount <= limits.maximumTotalByteCount else {
      throw .totalByteLimitExceeded(
        limit: limits.maximumTotalByteCount,
        requested: nextTotalByteCount
      )
    }
    let (nextUpdateCount, updateOverflow) = updateCount.addingReportingOverflow(1)
    guard !updateOverflow else {
      throw .byteCountOverflow
    }
    guard nextUpdateCount <= limits.maximumUpdateCount else {
      throw .updateCountLimitExceeded(
        limit: limits.maximumUpdateCount,
        requested: nextUpdateCount
      )
    }

    try backend.update(bytes)
    totalByteCount = nextTotalByteCount
    updateCount = nextUpdateCount
  }

  package func finalize() throws(ContentDigestError) -> ContentDigestResult {
    guard lifecycle == .active else {
      throw .sessionStateViolation
    }
    lifecycle = .finalizing
    do {
      let digest = try backend.finalize()
      lifecycle = .finished
      return ContentDigestResult(
        digest: digest,
        totalByteCount: totalByteCount,
        updateCount: updateCount
      )
    } catch {
      lifecycle = .aborted
      throw error
    }
  }

  package func abort(after primary: ContentDigestError) -> ContentDigestError {
    guard lifecycle == .active || lifecycle == .finalizing else {
      return primary
    }
    lifecycle = .aborted
    do {
      try backend.abort()
      return primary
    } catch {
      return .abortFailed(primary: primary, abort: error)
    }
  }
}
