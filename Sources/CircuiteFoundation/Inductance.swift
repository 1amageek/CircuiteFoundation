public struct Inductance: Sendable, Hashable, Codable, Comparable {
  public let henries: Double

  public var nanohenries: Double { henries * 1e9 }
  public var picohenries: Double { henries * 1e12 }

  public init(henries: Double) throws {
    guard henries.isFinite else {
      throw ElectricalQuantityError.nonFiniteValue(quantity: "Inductance", value: henries)
    }
    self.henries = henries
  }

  public init(nanohenries: Double) throws {
    try self.init(henries: nanohenries * 1e-9)
  }

  public init(picohenries: Double) throws {
    try self.init(henries: picohenries * 1e-12)
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.henries < rhs.henries
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(henries: container.decode(Double.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(henries)
  }
}
