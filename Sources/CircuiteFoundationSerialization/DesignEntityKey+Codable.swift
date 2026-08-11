import CircuiteFoundation

extension DesignEntityKey: Codable {
  private enum CodingKeys: String, CodingKey {
    case databaseID
    case entityID
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      databaseID: try container.decode(DesignDatabaseID.self, forKey: .databaseID),
      entityID: try container.decode(DesignEntityID.self, forKey: .entityID)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(databaseID, forKey: .databaseID)
    try container.encode(entityID, forKey: .entityID)
  }
}
