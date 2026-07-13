import Foundation

public protocol ArtifactVerifying: Sendable {
  func verify(
    _ reference: ArtifactReference,
    relativeTo workspaceRoot: URL?
  ) -> ArtifactIntegrity
}
