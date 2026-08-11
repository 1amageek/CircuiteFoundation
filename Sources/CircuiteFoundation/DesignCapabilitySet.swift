public struct DesignCapabilitySet: Sendable, Hashable {
  public let descriptors: [DesignCapabilityDescriptor]

  public init(
    _ descriptors: [DesignCapabilityDescriptor]
  ) throws(SchemaCompatibilityError) {
    let ordered = descriptors.sorted { $0.capabilityID < $1.capabilityID }
    for index in ordered.indices.dropFirst()
      where ordered[index - 1].capabilityID == ordered[index].capabilityID {
      throw SchemaCompatibilityError.duplicateCapability(
        ordered[index].capabilityID
      )
    }
    self.descriptors = ordered
  }

}
