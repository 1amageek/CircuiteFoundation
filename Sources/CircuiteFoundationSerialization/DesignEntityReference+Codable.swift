import CircuiteFoundation

extension DesignEntityReference: Codable {
  private enum CodingKeys: String, CodingKey {
    case revision
    case facetID
    case kindID
    case entityID
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      revision: try container.decode(DesignRevisionReference.self, forKey: .revision),
      facetID: try container.decode(DesignFacetID.self, forKey: .facetID),
      kindID: try container.decode(DesignEntityKindID.self, forKey: .kindID),
      entityID: try container.decode(DesignEntityID.self, forKey: .entityID)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(revision, forKey: .revision)
    try container.encode(facetID, forKey: .facetID)
    try container.encode(kindID, forKey: .kindID)
    try container.encode(entityID, forKey: .entityID)
  }
}
