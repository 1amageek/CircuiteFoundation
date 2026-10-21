/// Adapts the caller's existing invocation accountant; it introduces no budget.
public protocol ContentDigestConstructionControl: Sendable {
  func check() throws
  func charge(workUnits: UInt64) throws

  /// The returned shared owner must release temporary capacity on last release.
  func reserveTemporary(byteCount: UInt64) throws -> any Sendable

  /// Keep this reservation until the caller's last bounded result or failure
  /// owner releases this control. ContentDigest itself does not own a lease.
  func reserveRetained(byteCount: UInt64) throws
}
