import CircuiteFoundation
import Foundation
import Testing

@Suite
struct FoundationMigrationTests {
  @Test
  func artifactRoleRejectsInvalidTokensAndRoundTrips() throws {
    #expect(ArtifactRole(rawValue: "") == nil)
    #expect(ArtifactRole(rawValue: " invalid") == nil)
    #expect(ArtifactRole(rawValue: "../output") == nil)
    #expect(ArtifactRole(rawValue: "input") == .input)

    let encoded = try JSONEncoder().encode(ArtifactRole.input)
    let decoded = try JSONDecoder().decode(ArtifactRole.self, from: encoded)
    #expect(decoded == .input)
  }

  @Test
  func roleParticipatesInDerivedArtifactIdentity() throws {
    let location = try ArtifactLocation(workspaceRelativePath: "reports/timing.json")
    let digest = try ContentDigest(
      algorithm: .sha256,
      hexadecimalValue: String(repeating: "a", count: 64)
    )

    let input = ArtifactReference(
      locator: ArtifactLocator(
        location: location,
        role: .input,
        kind: .report,
        format: .json
      ),
      digest: digest,
      byteCount: 1
    )
    let output = ArtifactReference(
      locator: ArtifactLocator(
        location: location,
        role: .output,
        kind: .report,
        format: .json
      ),
      digest: digest,
      byteCount: 1
    )

    #expect(input.id != output.id)
  }

  @Test
  func executionInvocationRoundTripsBothExecutionModes() throws {
    let inProcess = try ExecutionInvocation.inProcess(entryPoint: "LogicEngine.simulate")
    let external = try ExecutionInvocation.externalProcess(
      executable: "/usr/bin/spice",
      arguments: ["-b", "input.cir"],
      workingDirectory: "/tmp/run"
    )

    let encoded = try JSONEncoder().encode([inProcess, external])
    let decoded = try JSONDecoder().decode([ExecutionInvocation].self, from: encoded)

    #expect(decoded == [inProcess, external])
  }

  @Test
  func executionInvocationRejectsMixedModes() {
    #expect(throws: ExecutionInvocationError.invalidInProcessFields) {
      try ExecutionInvocation(
        mode: .inProcess,
        entryPoint: "Engine.run",
        executable: "/usr/bin/tool",
        arguments: [],
        workingDirectory: nil
      )
    }
    #expect(throws: ExecutionInvocationError.argumentContainsControlCharacter("bad\narg")) {
      try ExecutionInvocation.externalProcess(executable: "/usr/bin/tool", arguments: ["bad\narg"])
    }
  }

  @Test
  func provenanceRoundTripsInvocationAndEnvironment() throws {
    let producer = try ProducerIdentity(
      kind: .engine,
      identifier: "LogicEngine",
      version: "1.0.0"
    )
    let invocation = try ExecutionInvocation.inProcess(entryPoint: "LogicEngine.simulate")
    let environment = try ExecutionEnvironmentFingerprint(
      platform: "macOS",
      architecture: "arm64",
      toolchain: "swift-6.3.1"
    )
    let instant = Date(timeIntervalSince1970: 10)
    let provenance = try ExecutionProvenance(
      producer: producer,
      invocation: invocation,
      environment: environment,
      startedAt: instant,
      completedAt: instant
    )

    let encoded = try JSONEncoder().encode(provenance)
    let decoded = try JSONDecoder().decode(ExecutionProvenance.self, from: encoded)

    #expect(decoded == provenance)
  }

  @Test
  func legacyArtifactReferenceDecodesWithSentinelRole() throws {
    let data = Data(#"{"location":{"storage":"workspaceRelative","value":"report.json"},"kind":"report","format":"json"}"#.utf8)
    let locator = try JSONDecoder().decode(ArtifactLocator.self, from: data)

    #expect(locator.role == .legacyUnspecified)
  }

  @Test
  func legacyEvidenceWithoutSchemaDefaultsToV1() throws {
    let producer = try ProducerIdentity(kind: .engine, identifier: "legacy", version: "1")
    let instant = Date(timeIntervalSince1970: 10)
    let provenance = try ExecutionProvenance(
      producer: producer,
      startedAt: instant,
      completedAt: instant
    )
    let jsonObject = try JSONSerialization.jsonObject(
      with: JSONEncoder().encode(EvidenceManifest(schemaVersion: .v1, provenance: provenance, artifacts: []))
    )
    guard var object = jsonObject as? [String: Any] else {
      Issue.record("Legacy evidence fixture did not encode as an object")
      return
    }
    object.removeValue(forKey: "schemaVersion")
    let data = try JSONSerialization.data(withJSONObject: object)

    let decoded = try JSONDecoder().decode(EvidenceManifest.self, from: data)
    #expect(decoded.schemaVersion == .v1)
  }
}
