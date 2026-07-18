import Foundation

public struct DatabaseUnitScale: Sendable, Hashable, Codable {
  public let databaseUnitsPerMicrometer: Double

  /// A one-nanometer database grid: 1,000 database units per micrometer.
  public static let nanometerGrid = Self(validatedDatabaseUnitsPerMicrometer: 1_000)

  public init(databaseUnitsPerMicrometer: Double) throws {
    guard databaseUnitsPerMicrometer.isFinite, databaseUnitsPerMicrometer > 0 else {
      throw DatabaseUnitScaleError.invalidScale(databaseUnitsPerMicrometer)
    }
    self.databaseUnitsPerMicrometer = databaseUnitsPerMicrometer
  }

  public func length(forDatabaseUnits value: Int64) -> Measurement<UnitLength> {
    Measurement(
      value: Double(value) / databaseUnitsPerMicrometer,
      unit: .micrometers
    )
  }

  public func databaseUnits(
    for length: Measurement<UnitLength>,
    rounding rule: FloatingPointRoundingRule = .toNearestOrEven
  ) throws -> Int64 {
    let micrometers = length.converted(to: .micrometers).value
    guard micrometers.isFinite else {
      throw DatabaseUnitScaleError.nonFiniteLength(micrometers)
    }
    let scaled = micrometers * databaseUnitsPerMicrometer
    let rounded = scaled.rounded(rule)
    let exclusiveUpperBound = 9_223_372_036_854_775_808.0
    let inclusiveLowerBound = -9_223_372_036_854_775_808.0
    guard rounded >= inclusiveLowerBound, rounded < exclusiveUpperBound else {
      throw DatabaseUnitScaleError.valueOutOfRange(rounded)
    }
    return Int64(rounded)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(databaseUnitsPerMicrometer: container.decode(Double.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(databaseUnitsPerMicrometer)
  }

  private init(validatedDatabaseUnitsPerMicrometer value: Double) {
    databaseUnitsPerMicrometer = value
  }
}
