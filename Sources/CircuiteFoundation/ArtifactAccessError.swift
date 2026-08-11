public enum ArtifactAccessError: Error, Sendable, Equatable {
  case invalidIntent(ArtifactAccessIntentError)
  case unsupportedCapability(reason: String)
  case availabilityNotLocal
  case rootMismatch(expected: ArtifactRootID, actual: ArtifactRootID)
  case invalidRoot(reason: String)
  case symlinkTraversal(componentIndex: Int)
  case nonRegularResource
  case openFailed(componentIndex: Int, reason: String)
  case metadataFailed(reason: String)
  case resourceUnavailable
  case resourceGenerationChanged
  case noncontiguousOffset(expected: UInt64, actual: UInt64)
  case pageByteLimitExceeded(limit: UInt64, requested: UInt64)
  case totalByteLimitExceeded(limit: UInt64, requested: UInt64)
  case pageCountLimitExceeded(limit: UInt64, requested: UInt64)
  case workLimitExceeded(limit: UInt64, requested: UInt64)
  case deadlineExceeded
  case truncatedResource
  case byteCountMismatch(expected: UInt64, actual: UInt64)
  case contentDigestMismatch(expected: ContentDigest, actual: ContentDigest)
  case contentIdentityMismatch(expected: ArtifactID, actual: ArtifactID)
  case readFailed(reason: String)
  case fileCloseFailed(reason: String)
  case cleanupFailed(primary: String, closeReason: String)
  case cancelled
  case sessionClosed
}
