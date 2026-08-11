import CircuiteFoundation

extension DesignCompatibilityReport: Codable {
  private enum CodingKeys: String, CodingKey {
    case agreedSchemas
    case agreedCapabilities
    case missingRequiredSchemas
    case incompatibleRequiredSchemas
    case missingRequiredCapabilities
    case incompatibleRequiredCapabilities
    case limitations
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      agreedSchemas: try container.decode(
        [DesignSchemaDescriptor].self,
        forKey: .agreedSchemas
      ),
      agreedCapabilities: try container.decode(
        [DesignCapabilityDescriptor].self,
        forKey: .agreedCapabilities
      ),
      missingRequiredSchemas: try container.decode(
        [DesignSchemaRequirement].self,
        forKey: .missingRequiredSchemas
      ),
      incompatibleRequiredSchemas: try container.decode(
        [DesignSchemaRequirement].self,
        forKey: .incompatibleRequiredSchemas
      ),
      missingRequiredCapabilities: try container.decode(
        [DesignCapabilityRequirement].self,
        forKey: .missingRequiredCapabilities
      ),
      incompatibleRequiredCapabilities: try container.decode(
        [DesignCapabilityRequirement].self,
        forKey: .incompatibleRequiredCapabilities
      ),
      limitations: try container.decode(
        [DesignCapabilityRequirement].self,
        forKey: .limitations
      )
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(agreedSchemas, forKey: .agreedSchemas)
    try container.encode(agreedCapabilities, forKey: .agreedCapabilities)
    try container.encode(missingRequiredSchemas, forKey: .missingRequiredSchemas)
    try container.encode(
      incompatibleRequiredSchemas,
      forKey: .incompatibleRequiredSchemas
    )
    try container.encode(
      missingRequiredCapabilities,
      forKey: .missingRequiredCapabilities
    )
    try container.encode(
      incompatibleRequiredCapabilities,
      forKey: .incompatibleRequiredCapabilities
    )
    try container.encode(limitations, forKey: .limitations)
  }
}
