public struct Capacitance: Sendable, Hashable, Codable, Comparable {
  public let farads: Double

  public var femtofarads: Double { farads * 1e15 }
  public var picofarads: Double { farads * 1e12 }

  public init(farads: Double) throws {
    guard farads.isFinite else {
      throw ElectricalQuantityError.nonFiniteValue(quantity: "Capacitance", value: farads)
    }
    self.farads = farads
  }

  public init(femtofarads: Double) throws {
    try self.init(farads: femtofarads * 1e-15)
  }

  public init(picofarads: Double) throws {
    try self.init(farads: picofarads * 1e-12)
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.farads < rhs.farads
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(farads: container.decode(Double.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(farads)
  }
}
