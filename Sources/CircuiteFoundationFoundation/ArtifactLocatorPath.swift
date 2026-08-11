import Foundation

public extension ArtifactLocator {
  var path: String {
    switch location.storage {
    case .workspaceRelative:
      location.value
    case .absoluteFileURL:
      URL(string: location.value)?.path ?? location.value
    }
  }
}
