import CircuiteFoundation

extension DesignSchemaRequirement: Codable {
  private enum CodingKeys: String, CodingKey {
    case schemaID
    case versions
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      schemaID: try container.decode(DesignSchemaID.self, forKey: .schemaID),
      versions: try container.decode(SchemaVersionRange.self, forKey: .versions)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(schemaID, forKey: .schemaID)
    try container.encode(versions, forKey: .versions)
  }
}
