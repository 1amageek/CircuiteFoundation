import CircuiteFoundation
import CircuiteFoundationFoundation
import Foundation

public protocol ArtifactVerifying: Sendable {
  func verify(
    _ reference: ArtifactReference,
    at locator: ArtifactLocator,
    relativeTo workspaceRoot: URL?
  ) -> ArtifactIntegrity
}
