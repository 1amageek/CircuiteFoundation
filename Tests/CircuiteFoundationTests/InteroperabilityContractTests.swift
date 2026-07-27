import Foundation
import Testing
@testable import CircuiteFoundation

@Suite
struct InteroperabilityContractTests {
  @Test
  func externalBackendCannotBecomeCanonicalPrimary() {
    #expect(throws: InteroperabilityContractError.self) {
      _ = try InteroperabilityExecutionPlan(
        backend: .external(.openROAD),
        purpose: .primary
      )
    }
  }

  @Test
  func explicitOraclePlanRoundTripsThroughCodable() throws {
    let plan = try InteroperabilityExecutionPlan(
      backend: .external(.googleXLS),
      purpose: .oracle
    )
    let data = try JSONEncoder().encode(plan)
    #expect(try JSONDecoder().decode(InteroperabilityExecutionPlan.self, from: data) == plan)
  }

  @Test
  func semanticLossFailsClosed() throws {
    let loss = try InteroperabilityLoss(
      systemID: .openDB,
      severity: .error,
      kind: .unmappedObject,
      code: "unmapped-via-rule",
      message: "The external via rule has no registered canonical mapping.",
      sourcePath: "block/via_rules/VR1"
    )
    let report = InteroperabilityReport(
      sourceSystem: .openDB,
      targetSystem: .lsi,
      direction: .importToLSI,
      mappedObjectCount: 4,
      unmappedSemanticCount: 1,
      losses: [loss]
    )

    #expect(!report.isSemanticallyComplete)
    #expect(throws: InteroperabilityContractError.self) {
      try report.requireSemanticCompleteness()
    }
  }
}
