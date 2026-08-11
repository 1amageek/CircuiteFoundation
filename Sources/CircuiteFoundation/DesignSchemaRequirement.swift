public struct DesignSchemaRequirement: Sendable, Hashable {
  public let schemaID: DesignSchemaID
  public let versions: SchemaVersionRange

  public init(schemaID: DesignSchemaID, versions: SchemaVersionRange) {
    self.schemaID = schemaID
    self.versions = versions
  }
}
