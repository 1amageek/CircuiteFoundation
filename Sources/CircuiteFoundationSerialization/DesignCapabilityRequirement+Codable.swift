import CircuiteFoundation

extension DesignCapabilityRequirement: Codable {
  private enum CodingKeys: String, CodingKey {
    case capabilityID
    case versions
    case necessity
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      capabilityID: try container.decode(DesignCapabilityID.self, forKey: .capabilityID),
      versions: try container.decode(SchemaVersionRange.self, forKey: .versions),
      necessity: try container.decode(Necessity.self, forKey: .necessity)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(capabilityID, forKey: .capabilityID)
    try container.encode(versions, forKey: .versions)
    try container.encode(necessity, forKey: .necessity)
  }
}

extension DesignCapabilityRequirement.Necessity: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    guard let value = Self(rawValue: rawValue) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unknown capability necessity."
      )
    }
    self = value
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
