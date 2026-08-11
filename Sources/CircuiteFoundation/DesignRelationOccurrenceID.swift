public struct DesignRelationOccurrenceID:
  Sendable,
  Hashable,
  Comparable,
  CustomStringConvertible
{
  public let rawValue: UInt64

  public var description: String {
    FixedWidthHexadecimal.encode(rawValue)
  }

  public init(rawValue: UInt64) throws {
    guard rawValue != 0 else {
      throw DesignIdentityError.zeroIdentity(
        kind: "DesignRelationOccurrenceID"
      )
    }
    self.rawValue = rawValue
  }

  public init(hexadecimalValue: String) throws {
    try self.init(
      rawValue: FixedWidthHexadecimal.decode64(
        hexadecimalValue,
        kind: "DesignRelationOccurrenceID"
      )
    )
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
