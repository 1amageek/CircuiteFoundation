public struct Conductance: Sendable, Hashable, Codable, Comparable {
  public let siemens: Double

  public var millisiemens: Double { siemens * 1e3 }
  public var microsiemens: Double { siemens * 1e6 }

  public init(siemens: Double) throws {
    guard siemens.isFinite else {
      throw ElectricalQuantityError.nonFiniteValue(quantity: "Conductance", value: siemens)
    }
    self.siemens = siemens
  }

  public init(millisiemens: Double) throws {
    try self.init(siemens: millisiemens * 1e-3)
  }

  public init(microsiemens: Double) throws {
    try self.init(siemens: microsiemens * 1e-6)
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.siemens < rhs.siemens
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(siemens: container.decode(Double.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(siemens)
  }
}
