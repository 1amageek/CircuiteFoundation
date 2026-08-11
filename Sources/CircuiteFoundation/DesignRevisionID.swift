public struct DesignRevisionID: Sendable, Hashable, CustomStringConvertible {
  public let high: UInt64
  public let low: UInt64

  public var description: String {
    FixedWidthHexadecimal.encode(high: high, low: low)
  }

  public init(high: UInt64, low: UInt64) {
    self.high = high
    self.low = low
  }

  public init(hexadecimalValue: String) throws {
    let words = try FixedWidthHexadecimal.decode128(
      hexadecimalValue,
      kind: "DesignRevisionID"
    )
    self.init(high: words.0, low: words.1)
  }

}
