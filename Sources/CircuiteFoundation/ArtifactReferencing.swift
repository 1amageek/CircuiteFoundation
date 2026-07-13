import Foundation

public protocol ArtifactReferencing: Sendable {
  func reference(
    _ locator: ArtifactLocator,
    relativeTo workspaceRoot: URL?,
    producer: ProducerIdentity?
  ) throws -> ArtifactReference
}
