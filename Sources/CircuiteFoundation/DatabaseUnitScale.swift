public struct DatabaseUnitScale: Sendable, Hashable {
  public let databaseUnitsPerMicrometer: Double

  /// A one-nanometer database grid: 1,000 database units per micrometer.
  public static let nanometerGrid = Self(validatedDatabaseUnitsPerMicrometer: 1_000)

  public init(databaseUnitsPerMicrometer: Double) throws {
    guard databaseUnitsPerMicrometer.isFinite, databaseUnitsPerMicrometer > 0 else {
      throw DatabaseUnitScaleError.invalidScale(databaseUnitsPerMicrometer)
    }
    self.databaseUnitsPerMicrometer = databaseUnitsPerMicrometer
  }

  public func micrometers(forDatabaseUnits value: Int64) -> Double {
    Double(value) / databaseUnitsPerMicrometer
  }

  public func databaseUnits(
    forMicrometers micrometers: Double,
    rounding rule: FloatingPointRoundingRule = .toNearestOrEven
  ) throws -> Int64 {
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

  private init(validatedDatabaseUnitsPerMicrometer value: Double) {
    databaseUnitsPerMicrometer = value
  }
}
