import CircuiteFoundation
import CircuiteFoundationFoundation
import Foundation

public protocol ArtifactReferencing: Sendable {
  func reference(
    _ locator: ArtifactLocator,
    relativeTo workspaceRoot: URL?
  ) throws -> ArtifactReference
}
