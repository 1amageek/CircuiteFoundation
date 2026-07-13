import Foundation

public enum TokenError: Error, Sendable, Equatable, LocalizedError {
  case empty(kind: String)
  case leadingOrTrailingWhitespace(kind: String, value: String)
  case containsControlCharacter(kind: String, value: String)

  public var errorDescription: String? {
    switch self {
    case .empty(let kind):
      "\(kind) cannot be empty."
    case .leadingOrTrailingWhitespace(let kind, let value):
      "\(kind) cannot have leading or trailing whitespace: \(value)"
    case .containsControlCharacter(let kind, let value):
      "\(kind) cannot contain control characters: \(value)"
    }
  }
}
