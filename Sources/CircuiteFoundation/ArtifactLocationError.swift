import Foundation

public enum ArtifactLocationError: Error, Sendable, Equatable, LocalizedError {
  case invalidWorkspaceRelativePath(String)
  case invalidFileURL(String)
  case nonFileURL(URL)
  case nonAbsoluteFileURL(URL)
  case missingWorkspaceRoot
  case workspaceRootIsNotAbsolute(URL)
  case outsideWorkspaceRoot(URL)

  public var errorDescription: String? {
    switch self {
    case .invalidWorkspaceRelativePath(let path):
      "Invalid workspace-relative artifact path: \(path)"
    case .invalidFileURL(let value):
      "Invalid artifact file URL: \(value)"
    case .nonFileURL(let url):
      "Artifact URL is not a file URL: \(url.absoluteString)"
    case .nonAbsoluteFileURL(let url):
      "Artifact file URL is not absolute: \(url.absoluteString)"
    case .missingWorkspaceRoot:
      "A workspace root is required for a workspace-relative artifact location."
    case .workspaceRootIsNotAbsolute(let url):
      "Workspace root is not an absolute file URL: \(url.absoluteString)"
    case .outsideWorkspaceRoot(let url):
      "Artifact resolves outside the workspace root: \(url.path)"
    }
  }
}
