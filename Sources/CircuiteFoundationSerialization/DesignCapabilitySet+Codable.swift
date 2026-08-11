import CircuiteFoundation

extension DesignCapabilitySet: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(container.decode([DesignCapabilityDescriptor].self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(descriptors)
  }
}
