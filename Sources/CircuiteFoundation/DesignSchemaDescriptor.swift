public struct DesignSchemaDescriptor: Sendable, Hashable, Codable {
  public let schemaID: DesignSchemaID
  public let facetID: DesignFacetID
  public let version: SchemaVersion
  public let canonicalDigest: ContentDigest
  public let requiredSchemas: [DesignSchemaRequirement]

  public init(
    schemaID: DesignSchemaID,
    facetID: DesignFacetID,
    version: SchemaVersion,
    canonicalDigest: ContentDigest,
    requiredSchemas: [DesignSchemaRequirement] = []
  ) throws(SchemaCompatibilityError) {
    var identifiers = Set<DesignSchemaID>()
    for requirement in requiredSchemas {
      guard identifiers.insert(requirement.schemaID).inserted else {
        throw SchemaCompatibilityError.duplicateSchema(requirement.schemaID)
      }
    }
    self.schemaID = schemaID
    self.facetID = facetID
    self.version = version
    self.canonicalDigest = canonicalDigest
    self.requiredSchemas = requiredSchemas.sorted { $0.schemaID < $1.schemaID }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      schemaID: container.decode(DesignSchemaID.self, forKey: .schemaID),
      facetID: container.decode(DesignFacetID.self, forKey: .facetID),
      version: container.decode(SchemaVersion.self, forKey: .version),
      canonicalDigest: container.decode(ContentDigest.self, forKey: .canonicalDigest),
      requiredSchemas: container.decode([DesignSchemaRequirement].self, forKey: .requiredSchemas)
    )
  }

  private enum CodingKeys: String, CodingKey {
    case schemaID
    case facetID
    case version
    case canonicalDigest
    case requiredSchemas
  }
}
