import Foundation

public extension ArtifactLocator {
  /// The serialized location value used by callers that do not need to
  /// resolve the location against a workspace root.
  var path: String {
    switch location.storage {
    case .workspaceRelative:
      return location.value
    case .absoluteFileURL:
      return URL(string: location.value)?.path ?? location.value
    }
  }
}
