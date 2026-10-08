import CircuiteFoundation

struct SourceDiscoveryAccounting {
  let started = ContinuousClock.now
  let maximumDurationNanoseconds: UInt64

  var elapsedNanoseconds: UInt64 {
    let components = started.duration(to: .now).components
    guard components.seconds >= 0 else { return 0 }
    let seconds = UInt64(components.seconds).multipliedReportingOverflow(by: 1_000_000_000)
    let fraction = UInt64(max(0, components.attoseconds / 1_000_000_000))
    let total = seconds.partialValue.addingReportingOverflow(fraction)
    return seconds.overflow || total.overflow ? UInt64.max : total.partialValue
  }

  func check(progress: ArtifactDirectoryInventoryProgress = .init())
    throws(ArtifactSourceDiscoveryError) {
    if Task.isCancelled { throw .cancelled(progress: progress) }
    if elapsedNanoseconds >= maximumDurationNanoseconds {
      throw .deadlineExceeded(progress: progress)
    }
  }

  static func closing<Result>(
    _ descriptor: Int32,
    close: (Int32) throws -> Void = POSIXArtifactFile.close,
    body: () throws(ArtifactSourceDiscoveryError) -> Result
  ) throws(ArtifactSourceDiscoveryError) -> Result {
    let result: Result
    do { result = try body() }
    catch {
      do { try close(descriptor) }
      catch let closeError {
        throw .cleanupFailed(primary: error, closeReason: String(describing: closeError))
      }
      throw error
    }
    do { try close(descriptor) }
    catch { throw .cleanupFailed(primary: nil, closeReason: String(describing: error)) }
    return result
  }
}
