import CircuiteFoundation

public indirect enum ArtifactSourceDiscoveryError: Error, Sendable, Equatable {
  case control(ArtifactSourceControlError)
  case access(ArtifactAccessError)
  case digest(ContentDigestError)
  case digestAbortFailed(primary: ArtifactSourceDiscoveryError, abort: ContentDigestError)
  case invalidInventoryLimits
  case cancelled(progress: ArtifactDirectoryInventoryProgress)
  case deadlineExceeded(progress: ArtifactDirectoryInventoryProgress)
  case entryLimitExceeded(limit: UInt64, progress: ArtifactDirectoryInventoryProgress)
  case depthLimitExceeded(limit: UInt64, progress: ArtifactDirectoryInventoryProgress)
  case resultLimitExceeded(limit: UInt64, progress: ArtifactDirectoryInventoryProgress)
  case workLimitExceeded(limit: UInt64, progress: ArtifactDirectoryInventoryProgress)
  case inventoryFailed(reason: String, progress: ArtifactDirectoryInventoryProgress)
  case cleanupFailed(primary: ArtifactSourceDiscoveryError?, closeReason: String)
}
