import CircuiteFoundation
import Synchronization

public enum CircuiteFoundationPortabilityProbeOutput {
  public static func make() throws -> String {
    let databaseID = try DesignDatabaseID(high: 1, low: 2)
    let subjectScopeID = try DesignAuthorizationSubjectScopeID(high: 3, low: 4)
    let revision = DesignRevisionReference(
      databaseID: databaseID,
      revisionID: DesignRevisionID(high: 5, low: 6)
    )
    let capability = DesignCapabilityDescriptor(
      capabilityID: try DesignCapabilityID(rawValue: "query.exact-revision"),
      versions: try SchemaVersionRange(
        lowerBound: SchemaVersion(major: 1, minor: 0, patch: 0),
        upperBound: SchemaVersion(major: 2, minor: 0, patch: 0)
      )
    )
    let capabilities = try DesignCapabilitySet([capability])
    let schemaID = try DesignSchemaID(rawValue: "lsi.portability")
    let schema = try DesignSchemaDescriptor(
      schemaID: schemaID,
      facetID: DesignFacetID(rawValue: "portability"),
      version: SchemaVersion(major: 1, minor: 0, patch: 0),
      canonicalDigest: ContentDigest(
        algorithm: .sha256,
        hexadecimalValue: String(repeating: "a", count: 64)
      )
    )
    let report = try DesignCompatibilityNegotiator.negotiate(
      offeredSchemas: [schema],
      requiredSchemas: [
        DesignSchemaRequirement(
          schemaID: schemaID,
          versions: try SchemaVersionRange(
            lowerBound: SchemaVersion(major: 1, minor: 0, patch: 0),
            upperBound: SchemaVersion(major: 2, minor: 0, patch: 0)
          )
        ),
      ],
      offeredCapabilities: capabilities,
      requiredCapabilities: [
        DesignCapabilityRequirement(
          capabilityID: capability.capabilityID,
          versions: capability.versions,
          necessity: .required
        ),
      ]
    )
    guard databaseID.description
            == "00000000000000010000000000000002",
          subjectScopeID.description
            == "00000000000000030000000000000004",
          revision.revisionID.description
            == "00000000000000050000000000000006",
          capabilities.descriptors == [capability],
          report.isCompatible,
          report.agreedSchemas == [schema],
          report.agreedCapabilities == [capability] else {
      throw PortabilityProbeError.canonicalValueMismatch
    }
    if #available(macOS 15, *) {
      try controlledDigestChecks()
    } else {
      throw PortabilityProbeError.controlledDigestProbeUnavailable
    }
    return [
      "CircuiteFoundationPortabilityProbe",
      databaseID.description,
      subjectScopeID.description,
      revision.revisionID.description,
      capability.capabilityID.rawValue,
      "controlled-digest-requirements:pass",
    ].joined(separator: ":")
  }

  @available(macOS 15, *)
  private static func controlledDigestChecks() throws {
    let text = String(repeating: "AbCd", count: 16)
    let legacy = try ContentDigest(algorithm: .sha256, hexadecimalValue: text)
    let ledger = ProbeLedger()
    var first: (any ContentDigestConstructionControl)? = ProbeControl(ledger)
    var last = first
    do {
      guard let control = first else { preconditionFailure("Missing caller control") }
      let controlled = try ContentDigest(algorithm: .sha256, hexadecimalValue: text, control: control)
      precondition(controlled == legacy && controlled.hexadecimalValue == text.lowercased())
      precondition(ledger.snapshot().temporary == 0 && ledger.snapshot().retained >= 64)
    }
    first = nil
    precondition(ledger.snapshot().retained >= 64)
    withExtendedLifetime(last) {}
    last = nil
    precondition(ledger.snapshot().retained == 0)

    let leaseLedger = ProbeLedger()
    let leaseControl: any ContentDigestConstructionControl = ProbeControl(leaseLedger)
    var lease: (any Sendable)? = try leaseControl.reserveTemporary(byteCount: 7)
    var lastLease = lease
    lease = nil
    precondition(leaseLedger.snapshot().temporary == 7)
    withExtendedLifetime(lastLease) {}
    lastLease = nil
    precondition(leaseLedger.snapshot().temporary == 0)

    for invalid in ["", "ABC", "İ", "K", "AB"] {
      let expected = try typedCause {
        _ = try ContentDigest(algorithm: .sha256, hexadecimalValue: invalid)
      }
      let failureLedger = ProbeLedger()
      var failureOwner: (any ContentDigestConstructionControl)? = ProbeControl(failureLedger)
      let actual = try typedCause {
        guard let control = failureOwner else { preconditionFailure("Missing failure owner") }
        _ = try ContentDigest(algorithm: .sha256, hexadecimalValue: invalid, control: control)
      }
      precondition(actual == expected && failureLedger.snapshot().temporary == 0)
      failureOwner = nil
      precondition(failureLedger.snapshot().retained == 0)
    }

    for (account, expected) in [
      (ProbeLedger(byteLimit: 0), ProbeRefusal.quota),
      (ProbeLedger(workLimit: 0), ProbeRefusal.work),
      (ProbeLedger(cancelAt: 2), ProbeRefusal.cancelled),
      (ProbeLedger(failCharge: true), ProbeRefusal.callback)
    ] {
      var control: (any ContentDigestConstructionControl)? = ProbeControl(account)
      do {
        guard let current = control else { preconditionFailure("Missing callback owner") }
        _ = try ContentDigest(algorithm: .sha256, hexadecimalValue: text, control: current)
        preconditionFailure("Caller failure was ignored")
      } catch ProbeRefusal.quota { precondition(expected == .quota) }
       catch ProbeRefusal.work { precondition(expected == .work) }
       catch ProbeRefusal.cancelled { precondition(expected == .cancelled) }
       catch ProbeRefusal.callback { precondition(expected == .callback) }
      precondition(account.snapshot().temporary == 0)
      control = nil
      precondition(account.snapshot().retained == 0)
    }
  }

  private static func typedCause(_ operation: () throws -> Void) throws -> ContentDigestError {
    do { try operation(); preconditionFailure("Invalid digest was accepted") }
    catch ContentDigestError.emptyHexadecimalValue { return .emptyHexadecimalValue }
    catch ContentDigestError.invalidHexadecimalValue(let text) { return .invalidHexadecimalValue(text) }
    catch ContentDigestError.incompleteByte(let text) { return .incompleteByte(text) }
    catch ContentDigestError.invalidLength(let algorithm, let actual, let expected) {
      return .invalidLength(algorithm: algorithm, actual: actual, expected: expected)
    }
  }

  private enum ProbeRefusal: Error, Equatable, Sendable {
    case quota
    case work
    case cancelled
    case callback
  }

  @available(macOS 15, *)
  private final class ProbeLedger: Sendable {
    struct State: Sendable {
      var temporary: UInt64 = 0
      var retained: UInt64 = 0
      var work: UInt64 = 0
      var checks = 0
    }
    let state = Mutex(State())
    let byteLimit: UInt64
    let workLimit: UInt64
    let cancelAt: Int?
    let failCharge: Bool

    init(byteLimit: UInt64 = .max, workLimit: UInt64 = .max,
      cancelAt: Int? = nil, failCharge: Bool = false) {
      self.byteLimit = byteLimit
      self.workLimit = workLimit
      self.cancelAt = cancelAt
      self.failCharge = failCharge
    }

    func snapshot() -> State { state.withLock { $0 } }
  }

  @available(macOS 15, *)
  private final class ProbeTemporary: Sendable {
    let ledger: ProbeLedger
    let count: UInt64

    init(_ ledger: ProbeLedger, _ count: UInt64) {
      self.ledger = ledger
      self.count = count
    }

    deinit { ledger.state.withLock { $0.temporary -= count } }
  }

  @available(macOS 15, *)
  private final class ProbeControl: ContentDigestConstructionControl {
    let ledger: ProbeLedger
    private let retained = Mutex<UInt64>(0)

    init(_ ledger: ProbeLedger) { self.ledger = ledger }

    func check() throws {
      try ledger.state.withLock { state in
        state.checks += 1
        if let at = ledger.cancelAt, state.checks >= at { throw ProbeRefusal.cancelled }
      }
    }

    func charge(workUnits: UInt64) throws {
      if ledger.failCharge { throw ProbeRefusal.callback }
      try ledger.state.withLock { state in
        let next = state.work.addingReportingOverflow(workUnits)
        guard !next.overflow, next.partialValue <= ledger.workLimit else { throw ProbeRefusal.work }
        state.work = next.partialValue
      }
    }

    func reserveTemporary(byteCount: UInt64) throws -> any Sendable {
      try ledger.state.withLock { state in
        let next = state.temporary.addingReportingOverflow(byteCount)
        guard !next.overflow, next.partialValue <= ledger.byteLimit else { throw ProbeRefusal.quota }
        state.temporary = next.partialValue
      }
      return ProbeTemporary(ledger, byteCount)
    }

    func reserveRetained(byteCount: UInt64) throws {
      try ledger.state.withLock { state in
        let next = state.retained.addingReportingOverflow(byteCount)
        guard !next.overflow, next.partialValue <= ledger.byteLimit else { throw ProbeRefusal.quota }
        state.retained = next.partialValue
      }
      retained.withLock { $0 += byteCount }
    }

    deinit {
      let amount = retained.withLock { $0 }
      ledger.state.withLock { $0.retained -= amount }
    }
  }

}

private enum PortabilityProbeError: Error {
  case canonicalValueMismatch
  case controlledDigestProbeUnavailable
}
