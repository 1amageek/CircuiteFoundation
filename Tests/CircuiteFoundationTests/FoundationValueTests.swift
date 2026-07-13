import CircuiteFoundation
import Foundation
import Testing

@Suite
struct FoundationValueTests {
  @Test
  func databaseUnitsRoundTripThroughFoundationMeasurement() throws {
    let scale = try DatabaseUnitScale(databaseUnitsPerMicrometer: 1_000)

    let length = scale.length(forDatabaseUnits: 1_250)
    let databaseUnits = try scale.databaseUnits(for: length)

    #expect(length.converted(to: .micrometers).value == 1.25)
    #expect(databaseUnits == 1_250)
  }

  @Test
  func databaseUnitConversionUsesExplicitRoundingRule() throws {
    let scale = try DatabaseUnitScale(databaseUnitsPerMicrometer: 10.0)
    let length = Measurement(value: 0.26, unit: UnitLength.micrometers)

    #expect(try scale.databaseUnits(for: length, rounding: .down) == 2)
    #expect(try scale.databaseUnits(for: length, rounding: .up) == 3)
  }

  @Test
  func databaseUnitScalePreservesFractionalFormatScale() throws {
    let scale = try DatabaseUnitScale(databaseUnitsPerMicrometer: 2.5)

    #expect(scale.length(forDatabaseUnits: 5).value == 2.0)
  }

  @Test
  func databaseUnitScaleRejectsInvalidScale() {
    #expect(throws: DatabaseUnitScaleError.self) {
      try DatabaseUnitScale(databaseUnitsPerMicrometer: .infinity)
    }
    #expect(throws: DatabaseUnitScaleError.self) {
      try DatabaseUnitScale(databaseUnitsPerMicrometer: 0)
    }
  }

  @Test
  func missingElectricalDimensionsUseFiniteSIStorage() throws {
    let capacitance = try Capacitance(picofarads: 2.5)
    let inductance = try Inductance(nanohenries: 4)
    let conductance = try Conductance(millisiemens: 3)

    #expect(abs(capacitance.farads - 2.5e-12) < 1e-24)
    #expect(abs(inductance.henries - 4e-9) < 1e-21)
    #expect(abs(conductance.siemens - 3e-3) < 1e-15)
  }

  @Test
  func nonFiniteElectricalQuantityIsRejected() {
    #expect(throws: ElectricalQuantityError.self) {
      try Capacitance(farads: .infinity)
    }
  }

  @Test
  func schemaVersionsAreLexicographicallyComparable() {
    #expect(
      SchemaVersion(major: 1, minor: 2, patch: 9)
        < SchemaVersion(major: 1, minor: 3, patch: 0)
    )
  }

  @Test
  func databaseUnitConversionRejectsInt64UpperBoundary() throws {
    let scale = try DatabaseUnitScale(databaseUnitsPerMicrometer: 1.0)
    let unrepresentable = Measurement(
      value: 9_223_372_036_854_775_808.0,
      unit: UnitLength.micrometers
    )

    #expect(throws: DatabaseUnitScaleError.self) {
      try scale.databaseUnits(for: unrepresentable)
    }
  }
}
