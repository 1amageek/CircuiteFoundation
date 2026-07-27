public struct DesignCapabilityDescriptor: Sendable, Hashable, Codable {
  public let capabilityID: DesignCapabilityID
  public let versions: SchemaVersionRange

  public init(capabilityID: DesignCapabilityID, versions: SchemaVersionRange) {
    self.capabilityID = capabilityID
    self.versions = versions
  }
}
