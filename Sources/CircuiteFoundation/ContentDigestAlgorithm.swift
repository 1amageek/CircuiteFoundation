public struct ContentDigestAlgorithm: Sendable, Hashable, Codable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Content digest algorithm")
    self.rawValue = rawValue
  }

  private init(uncheckedRawValue value: String) {
    rawValue = value
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(rawValue: container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public static let sha256 = Self(uncheckedRawValue: "sha256")
}
