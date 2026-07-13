import Foundation

public enum ContentDigestError: Error, Sendable, Equatable, LocalizedError {
  case emptyHexadecimalValue
  case invalidHexadecimalValue(String)
  case incompleteByte(String)
  case invalidLength(algorithm: ContentDigestAlgorithm, actual: Int, expected: Int)
  case unsupportedAlgorithm(ContentDigestAlgorithm)
  case unreadableFile(URL, reason: String)

  public var errorDescription: String? {
    switch self {
    case .emptyHexadecimalValue:
      "A content digest cannot be empty."
    case .invalidHexadecimalValue(let value):
      "Content digest contains non-hexadecimal characters: \(value)"
    case .incompleteByte(let value):
      "Content digest must contain complete hexadecimal bytes: \(value)"
    case .invalidLength(let algorithm, let actual, let expected):
      "Digest for \(algorithm.rawValue) contains \(actual) hexadecimal characters; expected \(expected)."
    case .unsupportedAlgorithm(let algorithm):
      "Unsupported content digest algorithm: \(algorithm.rawValue)"
    case .unreadableFile(let url, let reason):
      "Unable to read \(url.path): \(reason)"
    }
  }
}
