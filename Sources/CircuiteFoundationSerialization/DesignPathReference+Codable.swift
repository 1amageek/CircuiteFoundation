import CircuiteFoundation

extension DesignPathReference: Codable {
  private enum CodingKeys: String, CodingKey {
    case facetID
    case kindID
    case hierarchy
    case localIdentifier
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      facetID: container.decode(DesignFacetID.self, forKey: .facetID),
      kindID: container.decode(DesignEntityKindID.self, forKey: .kindID),
      hierarchy: container.decode(HierarchyPath.self, forKey: .hierarchy),
      localIdentifier: container.decode(String.self, forKey: .localIdentifier)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(facetID, forKey: .facetID)
    try container.encode(kindID, forKey: .kindID)
    try container.encode(hierarchy, forKey: .hierarchy)
    try container.encode(localIdentifier, forKey: .localIdentifier)
  }
}
