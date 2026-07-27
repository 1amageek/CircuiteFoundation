public struct DesignRevisionReference: Sendable, Hashable, Codable {
  public let databaseID: DesignDatabaseID
  public let revisionID: DesignRevisionID

  public init(databaseID: DesignDatabaseID, revisionID: DesignRevisionID) {
    self.databaseID = databaseID
    self.revisionID = revisionID
  }
}
