import CircuiteFoundationCrypto
import CircuiteFoundationFoundation
import Foundation
import Synchronization
import Testing
@testable import CircuiteFoundation

@Suite(.timeLimit(.minutes(1)))
struct ManagedEvidenceCostTests {
  enum PlanningFailure: Error, Equatable { case stopped(String) }
  @available(macOS 15.0, *)
  final class Observed: Sendable { let bytes = Mutex<[UInt8]>([]) }
  @available(macOS 15.0, *)
  struct RecordingDigester: ContentDigesting {
    let observed: Observed
    func digest(using algorithm: ContentDigestAlgorithm, limits: ContentDigestSessionLimits,
      _ body: (borrowing ContentDigestUpdateLease) throws(ContentDigestError) -> Void)
      throws(ContentDigestError) -> ContentDigestResult {
      try ContentDigestSessionRunner.run(backend: Backend(observed: observed), limits: limits, body)
    }
    final class Backend: ContentDigestSessionBackend {
      let observed: Observed
      init(observed: Observed) { self.observed = observed }
      func update(_ bytes: borrowing [UInt8]) throws(ContentDigestError) {
        let chunk = copy bytes
        observed.bytes.withLock { $0.append(contentsOf: chunk) }
      }
      func finalize() throws(ContentDigestError) -> ContentDigest {
        let bytes = observed.bytes.withLock { $0 }
        let limits = try ContentDigestSessionLimits(maximumChunkByteCount: max(UInt64(bytes.count), 1),
          maximumTotalByteCount: max(UInt64(bytes.count), 1), maximumUpdateCount: 1)
        return try SHA256ContentDigester().digest(using: .sha256, limits: limits) { (lease: borrowing ContentDigestUpdateLease) throws(ContentDigestError) in
          try lease.update(bytes)
        }.digest
      }
      func abort() throws(ContentDigestError) {}
    }
  }
  func artifact(long: Bool = false) throws -> ArtifactReference {
    let algorithm = try ContentDigestAlgorithm(rawValue: long ? "custom." + String(repeating: "a", count: 5000) : "custom")
    return try .init(digest: ContentDigest(algorithm: algorithm,
      hexadecimalValue: String(repeating: "ab", count: long ? 4000 : 16)), byteCount: .max,
      descriptor: .init(role: .input, kind: .model, format: .raw))
  }
  func provenance(full: Bool) throws -> ExecutionProvenance {
    let producer = try ProducerIdentity(kind: .engine, identifier: "engine.日本語", version: "1", build: full ? "release" : nil)
    let revision = try DesignRevisionReference(databaseID: .init(high: 1, low: 2), revisionID: .init(high: 3, low: 4))
    let digest = try ContentDigest(algorithm: .sha256, hexadecimalValue: String(repeating: "f", count: 64))
    return try .init(producer: producer, supportingTools: full ? [producer] : [], inputs: full ? [artifact()] : [],
      invocation: full ? .externalProcess(executable: "/tools/engine", arguments: ["", "日本語", String(repeating: "x", count: 4096)],
        workingDirectory: "/work") : nil,
      environment: full ? .init(platform: "macOS", architecture: "arm64", toolchain: "6.4", environmentDigest: digest) : nil,
      configurationDigest: full ? digest : nil, inputDesignRevision: full ? revision : nil,
      outputDesignRevision: full ? revision : nil, randomSeed: full ? .max : nil,
      startedAt: .init(secondsSinceUnixEpoch: 1), completedAt: .init(secondsSinceUnixEpoch: 2))
  }

  @Test func exactCountMatchesOriginalFactoryAndHashForWholeInputShape() throws {
    guard #available(macOS 15.0, *) else {
      Issue.record("Managed evidence capture requires macOS15 Mutex support")
      return
    }
    for full in [false, true] {
      let p = try provenance(full: full), artifacts = full ? [try artifact(), try artifact(long: true)] : []
      let schema = SchemaVersion(major: full ? .max : 0, minor: full ? .max : 0, patch: full ? .max : 0)
      var planningWork: UInt64 = 0
      let cost = try EvidenceManifest.canonicalizationCost(schemaVersion: schema, provenance: p, artifacts: artifacts) { planningWork += $0 }
      let observed = Observed()
      let recording = try EvidenceManifest.contentAddressed(schemaVersion: schema, provenance: p,
        artifacts: artifacts, digester: RecordingDigester(observed: observed))
      let original = try EvidenceManifest.contentAddressed(schemaVersion: schema, provenance: p,
        artifacts: artifacts, digester: SHA256ContentDigester())
      let count = observed.bytes.withLock { UInt64($0.count) }
      #expect(cost.canonicalByteCount == count)
      #expect(recording == original)
      #expect(cost.retainedByteCount == 0)
      #expect(cost.temporaryByteCount >= count)
      #expect(cost.workUnits >= count && planningWork > 0)
    }
  }
  @Test func planningRefusalPreservesOriginalCauseAtStartAndInsideStreamingTraversal() throws {
    let p = try provenance(full: true), a = try artifact(long: true)
    for stop in [1, 100] {
      var callbacks = 0
      do {
        _ = try EvidenceManifest.canonicalizationCost(provenance: p, artifacts: [a]) { _ in
          callbacks += 1
          if callbacks == stop { throw PlanningFailure.stopped("original-planning-cause") }
        }
        Issue.record("Planning cancellation was ignored")
      } catch let error as PlanningFailure {
        #expect(error == .stopped("original-planning-cause"))
        #expect(callbacks == stop)
      }
    }
  }
  @Test func dataAndFixedSHA256CostsHaveDistinctTemporaryAndRetainedLifetimes() throws {
    let data = Data("abc".utf8), digester = SHA256ContentDigester()
    let copy = try digester.foundationDataCopyCost(byteCount: UInt64(data.count))
    let hash = try SHA256ContentDigester.managedCost(byteCount: UInt64(data.count))
    let result = try digester.digest(data: data)
    #expect(result.hexadecimalValue == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    #expect(hash.retainedByteCount == UInt64(result.hexadecimalValue.utf8.count))
    #expect(copy.temporaryByteCount >= UInt64(data.count) && copy.workUnits == UInt64(data.count))
    #expect(hash.temporaryByteCount >= 16 + 64 + 64)
    #expect(hash.workUnits > UInt64(data.count))
  }
  @Test func checkedScalarLimitsRefuseBeforeAnyAllocationOrDigest() throws {
    #expect(throws: ContentDigestError.byteCountOverflow) { try SHA256ContentDigester.managedCost(byteCount: .max) }
    #expect(throws: ContentDigestError.byteCountOverflow) { try SHA256ContentDigester().foundationDataCopyCost(byteCount: .max) }
    #expect(throws: ContentDigestError.byteCountOverflow) { try EvidenceManifestCostArithmetic.add(.max, 1) }
    #expect(throws: ContentDigestError.byteCountOverflow) { try EvidenceManifestCostArithmetic.multiply(.max, 4) }
  }
}
