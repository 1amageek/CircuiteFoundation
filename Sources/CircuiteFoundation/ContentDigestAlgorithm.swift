public struct ContentDigestAlgorithm: Sendable, Hashable {
  public let rawValue: String

  public init(rawValue: String) throws(TokenError) {
    try TokenValidation.validate(rawValue, kind: "Content digest algorithm")
    self.rawValue = rawValue
  }

  private init(uncheckedRawValue value: String) {
    rawValue = value
  }

  public static let sha256 = Self(uncheckedRawValue: "sha256")
}
