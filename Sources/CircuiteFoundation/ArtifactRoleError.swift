import Foundation

public enum ArtifactRoleError: Error, Sendable, Equatable, LocalizedError {
  case containsPathSeparator(String)

  public var errorDescription: String? {
    switch self {
    case .containsPathSeparator(let value):
      "Artifact role must not contain a path separator: \(value)"
    }
  }
}
