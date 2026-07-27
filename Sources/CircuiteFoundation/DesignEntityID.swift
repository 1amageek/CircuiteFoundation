public struct DesignEntityID: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
  public let rawValue: UInt64

  public var description: String {
    FixedWidthHexadecimal.encode(rawValue)
  }

  public init(rawValue: UInt64) throws {
    guard rawValue != 0 else {
      throw DesignIdentityError.zeroIdentity(kind: "DesignEntityID")
    }
    self.rawValue = rawValue
  }

  public init(hexadecimalValue: String) throws {
    try self.init(
      rawValue: FixedWidthHexadecimal.decode64(
        hexadecimalValue,
        kind: "DesignEntityID"
      )
    )
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(hexadecimalValue: container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
