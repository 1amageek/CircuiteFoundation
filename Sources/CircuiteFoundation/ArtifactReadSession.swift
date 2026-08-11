public protocol ArtifactReadSession: AnyObject, Sendable {
  var identity: ArtifactAccessSessionIdentity { get }
  var expectedReference: ArtifactReference { get }

  func readPage(
    _ request: ArtifactReadPageRequest
  ) async throws(ArtifactAccessError) -> ArtifactReadPage

  func close() async -> any ArtifactAccessTermination
}
