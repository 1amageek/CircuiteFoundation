public struct ProducerKind: Sendable, Hashable, Codable, RawRepresentable,
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

  public static let engine = Self(rawValue: "engine")
  public static let library = Self(rawValue: "library")
  public static let tool = Self(rawValue: "tool")
}
