import CircuiteFoundation
import Foundation

public extension DatabaseUnitScale {
  func length(forDatabaseUnits value: Int64) -> Measurement<UnitLength> {
    Measurement(
      value: micrometers(forDatabaseUnits: value),
      unit: .micrometers
    )
  }

  func databaseUnits(
    for length: Measurement<UnitLength>,
    rounding rule: FloatingPointRoundingRule = .toNearestOrEven
  ) throws -> Int64 {
    try databaseUnits(
      forMicrometers: length.converted(to: .micrometers).value,
      rounding: rule
    )
  }
}
