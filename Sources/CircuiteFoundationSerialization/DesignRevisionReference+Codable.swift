import CircuiteFoundation

extension DesignRevisionReference: Codable {
  private enum CodingKeys: String, CodingKey {
    case databaseID
    case revisionID
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      databaseID: try container.decode(DesignDatabaseID.self, forKey: .databaseID),
      revisionID: try container.decode(DesignRevisionID.self, forKey: .revisionID)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(databaseID, forKey: .databaseID)
    try container.encode(revisionID, forKey: .revisionID)
  }
}
