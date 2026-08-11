public struct DesignSchemaDescriptor: Sendable, Hashable {
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
    let orderedRequirements = requiredSchemas.sorted {
      $0.schemaID < $1.schemaID
    }
    for index in orderedRequirements.indices.dropFirst()
      where orderedRequirements[index - 1].schemaID
        == orderedRequirements[index].schemaID {
      throw SchemaCompatibilityError.duplicateSchema(
        orderedRequirements[index].schemaID
      )
    }
    self.schemaID = schemaID
    self.facetID = facetID
    self.version = version
    self.canonicalDigest = canonicalDigest
    self.requiredSchemas = orderedRequirements
  }

}
