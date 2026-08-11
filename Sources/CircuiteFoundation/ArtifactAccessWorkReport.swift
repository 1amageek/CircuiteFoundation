public struct ArtifactAccessWorkReport: Sendable, Hashable {
  public let pageCount: UInt64
  public let workUnitCount: UInt64
  public let elapsedNanoseconds: UInt64

  public init(
    pageCount: UInt64,
    workUnitCount: UInt64,
    elapsedNanoseconds: UInt64
  ) {
    self.pageCount = pageCount
    self.workUnitCount = workUnitCount
    self.elapsedNanoseconds = elapsedNanoseconds
  }
}
