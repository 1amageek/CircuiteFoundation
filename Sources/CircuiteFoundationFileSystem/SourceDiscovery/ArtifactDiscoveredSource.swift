import CircuiteFoundation

/// Immutable observed content; discovery does not grant admission authority.
public struct ArtifactDiscoveredSource: Sendable {
  public let reference: ArtifactReference
  public let work: ArtifactAccessWorkReport
  private let storage: SourceDiscoveryStorage<[UInt8]>
  private let control: (any ArtifactSourceControl)?

  init(reference: ArtifactReference, pages: [[UInt8]], work: ArtifactAccessWorkReport,
       retentions: [any ArtifactSourceRetention] = [], control: (any ArtifactSourceControl)? = nil) {
    self.reference = reference
    self.storage = SourceDiscoveryStorage(elements: pages, retentions: retentions)
    self.work = work
    self.control = control
  }

  private init(reference: ArtifactReference, storage: SourceDiscoveryStorage<[UInt8]>,
               work: ArtifactAccessWorkReport, control: (any ArtifactSourceControl)?) {
    self.reference = reference
    self.storage = storage
    self.work = work
    self.control = control
  }

  func recordingElapsed(_ nanoseconds: UInt64) -> Self {
    Self(reference: reference, storage: storage,
         work: .init(pageCount: work.pageCount, workUnitCount: work.workUnitCount,
                     elapsedNanoseconds: nanoseconds), control: control)
  }

  public var byteCount: UInt64 { reference.byteCount }

  /// Borrows each contiguous page in order. The caller owns subsequent processing admission.
  public func withUnsafeBytePages(_ body: (UnsafeRawBufferPointer) throws -> Void) rethrows {
    for page in storage.elements { try page.withUnsafeBytes(body) }
  }

  /// Controlled multi-page copies require the explicit accounted borrowing method.
  public func withUnsafeBytes<Result>(
    _ body: (UnsafeRawBufferPointer) throws -> Result
  ) throws -> Result {
    if storage.elements.count <= 1 {
      return try (storage.elements.first ?? []).withUnsafeBytes(body)
    }
    guard control == nil else {
      throw ArtifactSourceDiscoveryError.control(.unsupportedCapability(
        reason: "A controlled multi-page source requires withAccountedUnsafeBytes."
      ))
    }
    return try storage.elements.flatMap { $0 }.withUnsafeBytes(body)
  }

  /// Reserves the complete temporary copy and copy work before materialization.
  public func withAccountedUnsafeBytes<Result>(
    _ body: (UnsafeRawBufferPointer) throws -> Result
  ) throws -> Result {
    guard let control else {
      throw ArtifactSourceDiscoveryError.control(.unsupportedCapability(
        reason: "Accounted contiguous borrowing requires the source's invocation control."
      ))
    }
    do { try control.check() }
    catch { throw ArtifactSourceDiscoveryError.control(error) }
    if storage.elements.count <= 1 {
      let result = try (storage.elements.first ?? []).withUnsafeBytes(body)
      do { try control.check() }
      catch { throw ArtifactSourceDiscoveryError.control(error) }
      return result
    }
    let retention: any ArtifactSourceRetention
    do {
      try control.charge(.init(workUnits: byteCount))
      retention = try control.retain(.temporaryBytes(byteCount))
    } catch { throw ArtifactSourceDiscoveryError.control(error) }
    defer { withExtendedLifetime(retention) {} }
    var contiguous: [UInt8] = []
    contiguous.reserveCapacity(Int(byteCount))
    for page in storage.elements { contiguous.append(contentsOf: page) }
    let result = try contiguous.withUnsafeBytes(body)
    do { try control.check() }
    catch { throw ArtifactSourceDiscoveryError.control(error) }
    return result
  }
}
