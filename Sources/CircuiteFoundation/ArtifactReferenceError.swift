import Foundation

public enum ArtifactReferenceError: Error, Sendable, Equatable, LocalizedError {
  case fileNotFound(URL)
  case notRegularFile(URL)
  case metadataUnavailable(URL, reason: String)
  case byteCountOverflow(URL)
  case changedDuringReference(URL)

  public var errorDescription: String? {
    switch self {
    case .fileNotFound(let url):
      "Artifact file does not exist: \(url.path)"
    case .notRegularFile(let url):
      "Artifact is not a regular file: \(url.path)"
    case .metadataUnavailable(let url, let reason):
      "Unable to inspect artifact metadata at \(url.path): \(reason)"
    case .byteCountOverflow(let url):
      "Artifact byte count cannot be represented as UInt64: \(url.path)"
    case .changedDuringReference(let url):
      "Artifact changed while it was being referenced: \(url.path)"
    }
  }
}
