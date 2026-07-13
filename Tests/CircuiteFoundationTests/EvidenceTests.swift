import CircuiteFoundation
import Foundation
import Testing

@Suite
struct EvidenceTests {
  @Test
  func provenanceRejectsImpossibleTimeline() {
    let start = Date(timeIntervalSince1970: 2)
    let completion = Date(timeIntervalSince1970: 1)

    #expect(throws: ExecutionProvenanceError.self) {
      try ExecutionProvenance(
        producer: ProducerIdentity(
          kind: .engine,
          identifier: "LVSEngine",
          version: "1.0.0"
        ),
        startedAt: start,
        completedAt: completion
      )
    }
  }

  @Test
  func evidenceManifestRecordsFactsWithoutVerdict() throws {
    let instant = Date(timeIntervalSince1970: 10)
    let provenance = try ExecutionProvenance(
      producer: ProducerIdentity(
        kind: .engine,
        identifier: "DRCEngine",
        version: "1.0.0"
      ),
      randomSeed: 7,
      startedAt: instant,
      completedAt: instant
    )
    let manifest = EvidenceManifest(provenance: provenance, artifacts: [])

    let encoded = try JSONEncoder().encode(manifest)
    let decoded = try JSONDecoder().decode(EvidenceManifest.self, from: encoded)

    #expect(decoded == manifest)
    #expect(decoded.provenance.randomSeed == 7)
    #expect(decoded.artifacts.isEmpty)
  }
}
