public protocol ArtifactAccessTermination: AnyObject, Sendable {
  var sessionIdentity: ArtifactAccessSessionIdentity { get }

  func wait() async throws(ArtifactAccessTerminationError) -> ArtifactAccessTerminationReceipt
}
