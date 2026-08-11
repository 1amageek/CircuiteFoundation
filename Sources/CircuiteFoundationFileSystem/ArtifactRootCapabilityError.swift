public enum ArtifactRootCapabilityError: Error, Sendable, Equatable {
  case invalidRoot(reason: String)
  case closeFailed(reason: String)
}
