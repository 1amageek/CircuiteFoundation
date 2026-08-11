public enum ArtifactAccessIntentError: Error, Sendable, Equatable {
  case availabilityIdentityMismatch(expected: ArtifactID, actual: ArtifactID)
}
