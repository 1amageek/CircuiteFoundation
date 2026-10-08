/// Planned cumulative work admitted before an action; failed attempts are not refunded.
public struct ArtifactSourceWork: Sendable, Hashable {
  public let readBytes: UInt64
  public let hashedBytes: UInt64
  public let pages: UInt64
  public let workUnits: UInt64
  public let visitedEntries: UInt64

  public init(readBytes: UInt64 = 0, hashedBytes: UInt64 = 0, pages: UInt64 = 0,
              workUnits: UInt64 = 0, visitedEntries: UInt64 = 0) {
    self.readBytes = readBytes
    self.hashedBytes = hashedBytes
    self.pages = pages
    self.workUnits = workUnits
    self.visitedEntries = visitedEntries
  }
}
