public struct ProducerKind: Sendable, Hashable, Codable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Producer kind")
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

  public static let engine = Self(uncheckedRawValue: "engine")
  public static let library = Self(uncheckedRawValue: "library")
  public static let tool = Self(uncheckedRawValue: "tool")
}
