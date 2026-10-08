public enum ArtifactSourceControlError: Error, Sendable, Equatable {
  case quotaExceeded(resource: ArtifactSourceResource, limit: UInt64, attempted: UInt64)
  case arithmeticOverflow(resource: ArtifactSourceResource)
  case cancelled
  case deadlineExceeded
  case closed
  case unsupportedCapability(reason: String)
}
