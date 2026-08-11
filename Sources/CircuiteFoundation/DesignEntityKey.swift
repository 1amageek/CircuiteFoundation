public struct DesignEntityKey: Sendable, Hashable {
  public let databaseID: DesignDatabaseID
  public let entityID: DesignEntityID

  public init(databaseID: DesignDatabaseID, entityID: DesignEntityID) {
    self.databaseID = databaseID
    self.entityID = entityID
  }
}
