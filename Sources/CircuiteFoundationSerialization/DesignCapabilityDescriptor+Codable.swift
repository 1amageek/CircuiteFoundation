import CircuiteFoundation

extension DesignCapabilityDescriptor: Codable {
  private enum CodingKeys: String, CodingKey {
    case capabilityID
    case versions
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      capabilityID: try container.decode(DesignCapabilityID.self, forKey: .capabilityID),
      versions: try container.decode(SchemaVersionRange.self, forKey: .versions)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(capabilityID, forKey: .capabilityID)
    try container.encode(versions, forKey: .versions)
  }
}
