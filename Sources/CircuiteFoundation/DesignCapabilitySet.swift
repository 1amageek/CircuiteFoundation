public struct DesignCapabilitySet: Sendable, Hashable, Codable {
  public let descriptors: [DesignCapabilityDescriptor]

  public init(
    _ descriptors: [DesignCapabilityDescriptor]
  ) throws(SchemaCompatibilityError) {
    var identifiers = Set<DesignCapabilityID>()
    for descriptor in descriptors {
      guard identifiers.insert(descriptor.capabilityID).inserted else {
        throw SchemaCompatibilityError.duplicateCapability(descriptor.capabilityID)
      }
    }
    self.descriptors = descriptors.sorted { $0.capabilityID < $1.capabilityID }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(container.decode([DesignCapabilityDescriptor].self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(descriptors)
  }
}
