import CircuiteFoundation

extension DesignSchemaDescriptor: Codable {
  private enum CodingKeys: String, CodingKey {
    case schemaID
    case facetID
    case version
    case canonicalDigest
    case requiredSchemas
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      schemaID: container.decode(DesignSchemaID.self, forKey: .schemaID),
      facetID: container.decode(DesignFacetID.self, forKey: .facetID),
      version: container.decode(SchemaVersion.self, forKey: .version),
      canonicalDigest: container.decode(ContentDigest.self, forKey: .canonicalDigest),
      requiredSchemas: container.decode(
        [DesignSchemaRequirement].self,
        forKey: .requiredSchemas
      )
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(schemaID, forKey: .schemaID)
    try container.encode(facetID, forKey: .facetID)
    try container.encode(version, forKey: .version)
    try container.encode(canonicalDigest, forKey: .canonicalDigest)
    try container.encode(requiredSchemas, forKey: .requiredSchemas)
  }
}
