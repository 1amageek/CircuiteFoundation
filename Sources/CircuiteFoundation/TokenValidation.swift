enum TokenValidation {
  static func validate(_ value: String, kind: String) throws(TokenError) {
    guard !value.isEmpty else {
      throw TokenError.empty(kind: kind)
    }
    guard !hasBoundaryWhitespace(value) else {
      throw TokenError.leadingOrTrailingWhitespace(kind: kind, value: value)
    }
    guard !containsControlCharacter(value) else {
      throw TokenError.containsControlCharacter(kind: kind, value: value)
    }
  }

  static func hasBoundaryWhitespace(_ value: String) -> Bool {
    value.first?.isWhitespace == true || value.last?.isWhitespace == true
  }

  static func containsControlCharacter(_ value: String) -> Bool {
    value.unicodeScalars.contains {
      $0.value < 0x20 || (0x7f...0x9f).contains($0.value)
    }
  }
}
