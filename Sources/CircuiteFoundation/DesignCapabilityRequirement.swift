public struct DesignCapabilityRequirement: Sendable, Hashable {
  public enum Necessity: String, Sendable, Hashable {
    case required
    case optional
  }

  public let capabilityID: DesignCapabilityID
  public let versions: SchemaVersionRange
  public let necessity: Necessity

  public init(
    capabilityID: DesignCapabilityID,
    versions: SchemaVersionRange,
    necessity: Necessity
  ) {
    self.capabilityID = capabilityID
    self.versions = versions
    self.necessity = necessity
  }
}
