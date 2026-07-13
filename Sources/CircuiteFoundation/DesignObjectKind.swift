public struct DesignObjectKind: Sendable, Hashable, Codable, RawRepresentable,
  ExpressibleByStringLiteral
{
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.init(rawValue: value)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    rawValue = try container.decode(String.self)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public static let cell = Self(rawValue: "cell")
  public static let instance = Self(rawValue: "instance")
  public static let net = Self(rawValue: "net")
  public static let pin = Self(rawValue: "pin")
  public static let port = Self(rawValue: "port")
}
