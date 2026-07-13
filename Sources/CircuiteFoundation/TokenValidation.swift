import Foundation

enum TokenValidation {
  static func validate(_ value: String, kind: String) throws {
    guard !value.isEmpty else {
      throw TokenError.empty(kind: kind)
    }
    guard value.trimmingCharacters(in: .whitespacesAndNewlines) == value else {
      throw TokenError.leadingOrTrailingWhitespace(kind: kind, value: value)
    }
    let hasControlCharacter = value.unicodeScalars.contains {
      CharacterSet.controlCharacters.contains($0)
    }
    guard !hasControlCharacter else {
      throw TokenError.containsControlCharacter(kind: kind, value: value)
    }
  }
}
