import CircuiteFoundation

extension SchemaCompatibilityError: Codable {
  private enum Kind: String, Codable {
    case invalidVersionRange
    case duplicateSchema
    case duplicateCapability
  }

  private enum CodingKeys: String, CodingKey {
    case kind
    case lowerBound
    case upperBound
    case schemaID
    case capabilityID
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Kind.self, forKey: .kind) {
    case .invalidVersionRange:
      self = .invalidVersionRange(
        lowerBound: try container.decode(SchemaVersion.self, forKey: .lowerBound),
        upperBound: try container.decode(SchemaVersion.self, forKey: .upperBound)
      )
    case .duplicateSchema:
      self = .duplicateSchema(
        try container.decode(DesignSchemaID.self, forKey: .schemaID)
      )
    case .duplicateCapability:
      self = .duplicateCapability(
        try container.decode(DesignCapabilityID.self, forKey: .capabilityID)
      )
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .invalidVersionRange(let lowerBound, let upperBound):
      try container.encode(Kind.invalidVersionRange, forKey: .kind)
      try container.encode(lowerBound, forKey: .lowerBound)
      try container.encode(upperBound, forKey: .upperBound)
    case .duplicateSchema(let schemaID):
      try container.encode(Kind.duplicateSchema, forKey: .kind)
      try container.encode(schemaID, forKey: .schemaID)
    case .duplicateCapability(let capabilityID):
      try container.encode(Kind.duplicateCapability, forKey: .kind)
      try container.encode(capabilityID, forKey: .capabilityID)
    }
  }
}
