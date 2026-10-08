import CircuiteFoundation

public struct ArtifactDirectoryInventory: Sendable {
  public let entries: [ArtifactDirectoryEntry]
  public let progress: ArtifactDirectoryInventoryProgress
  public let work: ArtifactAccessWorkReport

  init(entries: [ArtifactDirectoryEntry], progress: ArtifactDirectoryInventoryProgress,
       work: ArtifactAccessWorkReport) {
    self.entries = entries
    self.progress = progress
    self.work = work
  }
}
