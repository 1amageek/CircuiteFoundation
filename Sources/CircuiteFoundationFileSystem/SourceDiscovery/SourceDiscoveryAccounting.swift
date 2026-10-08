import CircuiteFoundation

struct SourceDiscoveryAccounting {
  let started = ContinuousClock.now
  let maximumDurationNanoseconds: UInt64
  let control: (any ArtifactSourceControl)?

  init(maximumDurationNanoseconds: UInt64, control: (any ArtifactSourceControl)? = nil) {
    self.maximumDurationNanoseconds = maximumDurationNanoseconds
    self.control = control
  }

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
    do { try control?.check() }
    catch { throw .control(error) }
    if Task.isCancelled { throw .cancelled(progress: progress) }
    if elapsedNanoseconds >= maximumDurationNanoseconds {
      throw .deadlineExceeded(progress: progress)
    }
  }

  func charge(_ work: ArtifactSourceWork) throws(ArtifactSourceDiscoveryError) {
    try check()
    do { try control?.charge(work) }
    catch { throw .control(error) }
  }

  func retain(_ extent: ArtifactSourceExtent) throws(ArtifactSourceDiscoveryError)
    -> (any ArtifactSourceRetention)? {
    try check()
    do { return try control?.retain(extent) }
    catch { throw .control(error) }
  }

  static func sum(_ lhs: UInt64, _ rhs: UInt64, resource: ArtifactSourceResource)
    throws(ArtifactSourceDiscoveryError) -> UInt64 {
    let total = lhs.addingReportingOverflow(rhs)
    guard !total.overflow else { throw .control(.arithmeticOverflow(resource: resource)) }
    return total.partialValue
  }

  static func byteExtent(_ count: UInt64, stride: Int, resource: ArtifactSourceResource)
    throws(ArtifactSourceDiscoveryError) -> UInt64 {
    let bytes = count.multipliedReportingOverflow(by: UInt64(stride))
    guard !bytes.overflow else { throw .control(.arithmeticOverflow(resource: resource)) }
    return bytes.partialValue
  }

  static func closing<Result>(
    _ descriptor: Int32,
    close: (Int32) throws -> Void = POSIXArtifactFile.close,
    retention: (any ArtifactSourceRetention)? = nil,
    body: () throws(ArtifactSourceDiscoveryError) -> Result
  ) throws(ArtifactSourceDiscoveryError) -> Result {
    defer { withExtendedLifetime(retention) {} }
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
