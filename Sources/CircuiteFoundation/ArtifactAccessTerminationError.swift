public enum ArtifactAccessTerminationError: Error, Sendable, Equatable {
  case cleanupFailed(reason: String)
}
