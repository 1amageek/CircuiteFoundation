public struct DesignDatabaseID: Sendable, Hashable, Codable, CustomStringConvertible {
  public let high: UInt64
  public let low: UInt64

  public var description: String {
    FixedWidthHexadecimal.encode(high: high, low: low)
  }

  public init(high: UInt64, low: UInt64) throws {
    guard high != 0 || low != 0 else {
      throw DesignIdentityError.zeroIdentity(kind: "DesignDatabaseID")
    }
    self.high = high
    self.low = low
  }

  public init(hexadecimalValue: String) throws {
    let words = try FixedWidthHexadecimal.decode128(
      hexadecimalValue,
      kind: "DesignDatabaseID"
    )
    try self.init(high: words.0, low: words.1)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(hexadecimalValue: container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}
