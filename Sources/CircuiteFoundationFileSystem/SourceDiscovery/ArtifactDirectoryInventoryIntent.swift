import CircuiteFoundation

public struct ArtifactDirectoryInventoryIntent: Sendable {
  public let rootID: ArtifactRootID
  /// nil starts at the owned root; a path is always relative to that root.
  public let start: ArtifactRelativePath?
  public let maximumVisitedEntryCount: UInt64
  public let maximumDepth: UInt64
  public let maximumResultCount: UInt64
  public let maximumWorkUnitCount: UInt64
  public let maximumDurationNanoseconds: UInt64

  public init(rootID: ArtifactRootID, start: ArtifactRelativePath? = nil,
              maximumVisitedEntryCount: UInt64, maximumDepth: UInt64,
              maximumResultCount: UInt64, maximumWorkUnitCount: UInt64,
              maximumDurationNanoseconds: UInt64) throws(ArtifactSourceDiscoveryError) {
    guard maximumVisitedEntryCount > 0, maximumDepth > 0, maximumResultCount > 0,
          maximumWorkUnitCount > 0, maximumDurationNanoseconds > 0 else {
      throw .invalidInventoryLimits
    }
    self.rootID = rootID
    self.start = start
    self.maximumVisitedEntryCount = maximumVisitedEntryCount
    self.maximumDepth = maximumDepth
    self.maximumResultCount = maximumResultCount
    self.maximumWorkUnitCount = maximumWorkUnitCount
    self.maximumDurationNanoseconds = maximumDurationNanoseconds
  }
}
