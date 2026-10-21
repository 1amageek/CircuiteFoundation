import CircuiteFoundation
import CircuiteFoundationFoundation
import Foundation
import Synchronization
import Testing

@Suite(.timeLimit(.minutes(1)))
struct ControlledContentDigestTests {
  private struct RawDigest: Encodable {
    let algorithm: String
    let hexadecimalValue: String
  }
  private struct Digests: Decodable, Sendable { let values: [ContentDigest] }
  private struct RawDigests: Encodable { let values: [RawDigest] }
  @available(macOS 15.0, *)
  private struct Document: Sendable {
    let value: Digests
    let control: Control
  }
  @available(macOS 15.0, *)
  private struct Failure: Error, Sendable {
    let cause: any Error
    let control: Control
  }
  private enum Refusal: Error, Equatable { case temporary, retained, work, cancelled }
  private enum Callback: Sendable, Equatable { case temporary, retained, work }

  @available(macOS 15.0, *)
  private final class Ledger: Sendable {
    struct State {
      var temporary: UInt64 = 0
      var retained: UInt64 = 0
      var peakTemporary: UInt64 = 0
      var work: UInt64 = 0
      var calls = 0
      var cancelled = false
      var callbacksAfterCancellation = 0
    }
    let state = Mutex(State())
    let temporaryLimit: UInt64
    let retainedLimit: UInt64
    let workLimit: UInt64
    let cancelAt: Int?
    let cancelOn: Callback?
    init(temporary: UInt64 = .max, retained: UInt64 = .max,
         work: UInt64 = .max, cancelAt: Int? = nil, cancelOn: Callback? = nil) {
      temporaryLimit = temporary; retainedLimit = retained
      workLimit = work; self.cancelAt = cancelAt
      self.cancelOn = cancelOn
    }
    func enterCallback() { state.withLock { if $0.cancelled { $0.callbacksAfterCancellation += 1 } } }
    func completeCallback(_ kind: Callback) {
      state.withLock { if cancelOn == kind { $0.cancelled = true } }
    }
    func check() throws {
      try state.withLock { state in
        state.calls += 1
        if let cancelAt, state.calls >= cancelAt { state.cancelled = true }
        if state.cancelled { throw Refusal.cancelled }
      }
    }
  }
  @available(macOS 15.0, *)
  private final class Temporary: Sendable {
    let ledger: Ledger
    let count: UInt64
    init(_ ledger: Ledger, _ count: UInt64) { self.ledger = ledger; self.count = count }
    deinit { ledger.state.withLock { $0.temporary -= count } }
  }
  @available(macOS 15.0, *)
  private final class Control: ContentDigestConstructionControl {
    private struct State { var retained: UInt64 = 0 }
    let ledger: Ledger
    private let state = Mutex(State())
    init(_ ledger: Ledger) { self.ledger = ledger }
    func check() throws { try ledger.check() }
    func charge(workUnits: UInt64) throws {
      ledger.enterCallback()
      try check()
      try ledger.state.withLock { state in
        let next = state.work.addingReportingOverflow(workUnits)
        guard !next.overflow, next.partialValue <= ledger.workLimit else { throw Refusal.work }
        state.work = next.partialValue
      }
      ledger.completeCallback(.work)
    }
    func reserveTemporary(byteCount: UInt64) throws -> any Sendable {
      ledger.enterCallback()
      try check()
      try ledger.state.withLock { state in
        let next = state.temporary.addingReportingOverflow(byteCount)
        guard !next.overflow, next.partialValue <= ledger.temporaryLimit else { throw Refusal.temporary }
        state.temporary = next.partialValue
        state.peakTemporary = max(state.peakTemporary, state.temporary)
      }
      ledger.completeCallback(.temporary)
      return Temporary(ledger, byteCount)
    }
    func reserveRetained(byteCount: UInt64) throws {
      ledger.enterCallback()
      try check()
      try ledger.state.withLock { state in
        let next = state.retained.addingReportingOverflow(byteCount)
        guard !next.overflow, next.partialValue <= ledger.retainedLimit else { throw Refusal.retained }
        state.retained = next.partialValue
      }
      state.withLock { $0.retained += byteCount }
      ledger.completeCallback(.retained)
    }
    deinit {
      let amount = state.withLock { $0.retained }
      ledger.state.withLock { $0.retained -= amount }
    }
  }

  private func bytes(_ texts: [String], algorithm: String = "sha256") throws -> Data {
    try JSONEncoder().encode(RawDigests(values: texts.map {
      RawDigest(algorithm: algorithm, hexadecimalValue: $0)
    }))
  }
  @available(macOS 15.0, *)
  private func decode(_ data: Data, ledger: Ledger) throws -> Document {
    let control = Control(ledger)
    let decoder = JSONDecoder()
    decoder.userInfo[ContentDigestDecodingContext.controlKey] = control
    do { return Document(value: try decoder.decode(Digests.self, from: data), control: control) }
    catch { throw Failure(cause: error, control: control) }
  }

  @Test func uppercaseAndCustomAlgorithmUseOriginalCheckedCodableAndWire() throws {
    guard #available(macOS 15.0, *) else {
      Issue.record("Controlled digest accounting fixture requires macOS 15 Mutex support")
      return
    }
    for (algorithm, text) in [("sha256", String(repeating: "AbCd", count: 16)),
                              ("custom", "ABCDEF012345")] {
      let data = try bytes([text], algorithm: algorithm)
      let legacy = try JSONDecoder().decode(Digests.self, from: data)
      let ledger = Ledger()
      do {
        let controlled = try decode(data, ledger: ledger)
        #expect(controlled.value.values == legacy.values)
        #expect(controlled.value.values.first?.hexadecimalValue == text.lowercased())
        #expect(ledger.state.withLock { $0.work } > 0)
        #expect(ledger.state.withLock { $0.retained } >= UInt64(text.lowercased().utf8.count))
        #expect(ledger.state.withLock { $0.temporary } == 0)
        #expect(try JSONEncoder().encode(controlled.value.values) == JSONEncoder().encode(legacy.values))
      }
      #expect(ledger.state.withLock { $0.retained } == 0)
    }
  }

  @Test func manyDigestReservationsSurviveDocumentCopiesUntilLastOwner() throws {
    guard #available(macOS 15.0, *) else {
      Issue.record("Controlled digest accounting fixture requires macOS 15 Mutex support")
      return
    }
    let ledger = Ledger()
    let data = try bytes(Array(repeating: String(repeating: "A", count: 64), count: 16))
    var first: Document? = try decode(data, ledger: ledger)
    var second = first
    let admitted = ledger.state.withLock { $0.retained }
    #expect(admitted >= 16 * 64)
    first = nil
    #expect(second?.value.values.count == 16)
    #expect(ledger.state.withLock { $0.retained } == admitted)
    second = nil
    #expect(ledger.state.withLock { $0.retained } == 0)
    #expect(ledger.state.withLock { $0.temporary } == 0)
  }

  @Test(arguments: [String(repeating: "A", count: 4096), "ABC", "İ", "K"])
  func invalidInputPreservesOriginalTypedCauseAndFailureCopies(_ text: String) throws {
    guard #available(macOS 15.0, *) else {
      Issue.record("Controlled digest accounting fixture requires macOS 15 Mutex support")
      return
    }
    let data = try bytes([text])
    let expected: ContentDigestError
    do {
      _ = try JSONDecoder().decode(Digests.self, from: data)
      Issue.record("Invalid digest unexpectedly decoded")
      return
    } catch let error as ContentDigestError { expected = error }
    let ledger = Ledger()
    var first: Failure?
    do { _ = try decode(data, ledger: ledger); Issue.record("Invalid controlled digest decoded") }
    catch let error as Failure { first = error }
    var second = first
    first = nil
    #expect(second?.cause as? ContentDigestError == expected)
    #expect(ledger.state.withLock { $0.work } > 0)
    #expect(ledger.state.withLock { $0.temporary } == 0)
    withExtendedLifetime(second) {}
    second = nil
    #expect(ledger.state.withLock { $0.retained } == 0)
  }

  @Test func actualDecodeRefusesTinyTemporaryRetainedAndWorkLimits() throws {
    guard #available(macOS 15.0, *) else {
      Issue.record("Controlled digest accounting fixture requires macOS 15 Mutex support")
      return
    }
    let data = try bytes([String(repeating: "A", count: 64), String(repeating: "B", count: 64)])
    for (ledger, expected) in [(Ledger(temporary: 0), Refusal.temporary),
                               (Ledger(retained: 64), Refusal.retained),
                               (Ledger(work: 0), Refusal.work)] {
      do { _ = try decode(data, ledger: ledger); Issue.record("Digest admission was bypassed") }
      catch let error as Failure { #expect(error.cause as? Refusal == expected) }
      #expect(ledger.state.withLock { $0.temporary } == 0)
      #expect(ledger.state.withLock { $0.retained } == 0)
    }
  }

  @Test func cancellationInsideNormalizationCannotPublishDecodedSuccess() throws {
    guard #available(macOS 15.0, *) else {
      Issue.record("Controlled digest accounting fixture requires macOS 15 Mutex support")
      return
    }
    let text = String(repeating: "A", count: 4096)
    for ledger in [Ledger(cancelAt: 10), Ledger(cancelOn: .temporary),
                   Ledger(cancelOn: .retained), Ledger(cancelOn: .work)] {
      do { _ = try decode(bytes([text]), ledger: ledger); Issue.record("Cancellation was ignored") }
      catch let error as Failure { #expect(error.cause as? Refusal == .cancelled) }
      #expect(ledger.state.withLock { $0.cancelled })
      #expect(ledger.state.withLock { $0.callbacksAfterCancellation } == 0)
      #expect(ledger.state.withLock { $0.temporary } == 0)
      #expect(ledger.state.withLock { $0.retained } == 0)
    }
  }

  @Test func presentWrongControlContextIsNotSilentlyLegacy() throws {
    guard #available(macOS 15.0, *) else {
      Issue.record("Controlled digest accounting fixture requires macOS 15 Mutex support")
      return
    }
    let decoder = JSONDecoder()
    decoder.userInfo[ContentDigestDecodingContext.controlKey] = "wrong-control"
    do {
      _ = try decoder.decode(Digests.self, from: bytes([String(repeating: "A", count: 64)]))
      Issue.record("Malformed controlled context silently selected legacy construction")
    } catch let error as ContentDigestDecodingError {
      #expect(error == .invalidControlContext)
    }
  }
}
