public protocol ArtifactAccessing: Sendable {
  func open(
    _ intent: ArtifactAccessIntent
  ) async throws(ArtifactAccessError) -> any ArtifactReadSession
}
