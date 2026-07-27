import Foundation

public struct DesignPathReference: Sendable, Hashable, Codable {
  public let facetID: DesignFacetID
  public let kindID: DesignEntityKindID
  public let hierarchy: HierarchyPath
  public let localIdentifier: String

  public init(
    facetID: DesignFacetID,
    kindID: DesignEntityKindID,
    hierarchy: HierarchyPath = .root,
    localIdentifier: String
  ) throws {
    try TokenValidation.validate(localIdentifier, kind: "Design path local identifier")
    self.facetID = facetID
    self.kindID = kindID
    self.hierarchy = hierarchy
    self.localIdentifier = localIdentifier
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

  private enum CodingKeys: String, CodingKey {
    case facetID
    case kindID
    case hierarchy
    case localIdentifier
  }
}
