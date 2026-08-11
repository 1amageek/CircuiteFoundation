public struct DesignAuthorizationSubjectScopeID:
  Sendable,
  Hashable,
  CustomStringConvertible
{
  public let high: UInt64
  public let low: UInt64

  public var description: String {
    FixedWidthHexadecimal.encode(high: high, low: low)
  }

  public init(high: UInt64, low: UInt64) throws {
    guard high != 0 || low != 0 else {
      throw DesignIdentityError.zeroIdentity(
        kind: "DesignAuthorizationSubjectScopeID"
      )
    }
    self.high = high
    self.low = low
  }

  public init(hexadecimalValue: String) throws {
    let words = try FixedWidthHexadecimal.decode128(
      hexadecimalValue,
      kind: "DesignAuthorizationSubjectScopeID"
    )
    try self.init(high: words.0, low: words.1)
  }

}
