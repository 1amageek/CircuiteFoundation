import CircuiteFoundation

/// Immutable observed content; discovery does not grant admission authority.
public struct ArtifactDiscoveredSource: Sendable, ArtifactOwnedBytes {
  public let reference: ArtifactReference
  public let work: ArtifactAccessWorkReport
  private let pages: [[UInt8]]

  init(reference: ArtifactReference, pages: [[UInt8]], work: ArtifactAccessWorkReport) {
    self.reference = reference
    self.pages = pages
    self.work = work
  }

  func recordingElapsed(_ nanoseconds: UInt64) -> Self {
    Self(reference: reference, pages: pages,
         work: .init(pageCount: work.pageCount, workUnitCount: work.workUnitCount,
                     elapsedNanoseconds: nanoseconds))
  }

  public var byteCount: UInt64 { reference.byteCount }

  /// Borrows each contiguous page in order. No additional content copy is made.
  public func withUnsafeBytePages(_ body: (UnsafeRawBufferPointer) throws -> Void) rethrows {
    for page in pages { try page.withUnsafeBytes(body) }
  }

  /// Materializes a contiguous view only at this explicit consumer boundary.
  public func withUnsafeBytes<Result>(
    _ body: (UnsafeRawBufferPointer) throws -> Result
  ) rethrows -> Result {
    if pages.count == 1 { return try pages[0].withUnsafeBytes(body) }
    // The public contiguous borrow requires one buffer; ingestion and hashing retain pages.
    let contiguous = pages.flatMap { $0 }
    return try contiguous.withUnsafeBytes(body)
  }
}
