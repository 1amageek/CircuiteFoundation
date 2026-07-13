public struct DesignObjectKind: Sendable, Hashable, Codable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Design object kind")
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

  public static let cell = Self(uncheckedRawValue: "cell")
  public static let instance = Self(uncheckedRawValue: "instance")
  public static let net = Self(uncheckedRawValue: "net")
  public static let pin = Self(uncheckedRawValue: "pin")
  public static let port = Self(uncheckedRawValue: "port")
}
