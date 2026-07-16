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
        producer: try ProducerIdentity(
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
      producer: try ProducerIdentity(
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

  @Test
  func evidenceManifestRejectsMissingRequiredCollections() throws {
    let instant = Date(timeIntervalSince1970: 10)
    let provenance = try ExecutionProvenance(
      producer: try ProducerIdentity(
        kind: .engine,
        identifier: "DRCEngine",
        version: "1.0.0"
      ),
      startedAt: instant,
      completedAt: instant
    )
    let manifest = EvidenceManifest(provenance: provenance, artifacts: [])
    let encoder = JSONEncoder()
    let encoded = try encoder.encode(manifest)
    var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    object.removeValue(forKey: "artifacts")
    let incomplete = try JSONSerialization.data(withJSONObject: object)

    #expect(throws: DecodingError.self) {
      _ = try JSONDecoder().decode(EvidenceManifest.self, from: incomplete)
    }
  }

  @Test
  func provenanceRejectsMissingRequiredInputCollection() throws {
    let instant = Date(timeIntervalSince1970: 10)
    let provenance = try ExecutionProvenance(
      producer: try ProducerIdentity(
        kind: .engine,
        identifier: "DRCEngine",
        version: "1.0.0"
      ),
      startedAt: instant,
      completedAt: instant
    )
    let encoded = try JSONEncoder().encode(provenance)
    var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    object.removeValue(forKey: "inputs")
    let incomplete = try JSONSerialization.data(withJSONObject: object)

    #expect(throws: DecodingError.self) {
      _ = try JSONDecoder().decode(ExecutionProvenance.self, from: incomplete)
    }
  }

  @Test
  func producerIdentityRequiresStableIdentityAndVersion() {
    #expect(throws: TokenError.self) {
      try ProducerIdentity(kind: .engine, identifier: "", version: "1.0.0")
    }
    #expect(throws: TokenError.self) {
      try ProducerIdentity(kind: .engine, identifier: "DRCEngine", version: "")
    }
  }

  @Test
  func provenanceRejectsNonFiniteTimestamp() {
    #expect(throws: ExecutionProvenanceError.self) {
      try ExecutionProvenance(
        producer: try ProducerIdentity(
          kind: .engine,
          identifier: "DRCEngine",
          version: "1.0.0"
        ),
        startedAt: Date(timeIntervalSinceReferenceDate: .nan),
        completedAt: Date(timeIntervalSinceReferenceDate: 1)
      )
    }
  }
}
