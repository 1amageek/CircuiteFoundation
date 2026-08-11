import Foundation

public enum ContentDigestFoundationError: Error, Sendable, LocalizedError {
  case unreadableFile(URL, reason: String)

  public var errorDescription: String? {
    switch self {
    case .unreadableFile(let url, let reason):
      "Unable to read \(url.path): \(reason)"
    }
  }
}
