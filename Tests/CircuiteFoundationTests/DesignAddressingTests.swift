import CircuiteFoundation
import Foundation
import Testing

@Suite
struct DesignAddressingTests {
  @Test
  func hierarchyPathUsesStableSlashSeparatedEncoding() throws {
    let path = try HierarchyPath(components: ["top", "cpu", "alu"])

    let encoded = try JSONEncoder().encode(path)
    let decoded = try JSONDecoder().decode(HierarchyPath.self, from: encoded)

    #expect(path.description == "top/cpu/alu")
    #expect(decoded == path)
  }

  @Test
  func hierarchyPathRejectsAmbiguousComponents() {
    #expect(throws: HierarchyPathError.self) {
      try HierarchyPath(components: ["top", "cpu/alu"])
    }
    #expect(throws: HierarchyPathError.self) {
      try HierarchyPath("top//alu")
    }
    #expect(throws: HierarchyPathError.self) {
      try HierarchyPath(components: ["top", " cpu"])
    }
  }

  @Test
  func diagnosticCarriesMachineReadableSubjectAndAction() throws {
    let subject = try DesignObjectReference(
      kind: .net,
      identifier: "clock",
      hierarchy: try HierarchyPath("top/cpu")
    )
    let diagnostic = DesignDiagnostic(
      code: try DiagnosticCode(rawValue: "timing.hold-violation"),
      severity: .error,
      summary: "Hold constraint is not met.",
      subject: subject,
      suggestedActions: [
        SuggestedAction(code: "inspect-min-delay", summary: "Inspect the minimum-delay path.")
      ]
    )

    #expect(diagnostic.subject == subject)
    #expect(diagnostic.suggestedActions.first?.code == "inspect-min-delay")
  }

  @Test
  func designObjectReferenceRequiresIdentifier() {
    #expect(throws: TokenError.self) {
      try DesignObjectReference(kind: .net, identifier: "")
    }
  }
}
