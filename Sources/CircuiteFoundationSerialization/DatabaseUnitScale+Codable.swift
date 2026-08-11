import CircuiteFoundation

extension DatabaseUnitScale: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(
      databaseUnitsPerMicrometer: container.decode(Double.self)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(databaseUnitsPerMicrometer)
  }
}
