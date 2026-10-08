public struct ArtifactDirectoryInventoryProgress: Sendable, Equatable {
  public let visitedEntryCount: UInt64
  public let resultCount: UInt64
  public let workUnitCount: UInt64

  init(visitedEntryCount: UInt64 = 0, resultCount: UInt64 = 0, workUnitCount: UInt64 = 0) {
    self.visitedEntryCount = visitedEntryCount
    self.resultCount = resultCount
    self.workUnitCount = workUnitCount
  }
}
