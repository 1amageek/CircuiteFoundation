public struct DesignPathReference: Sendable, Hashable {
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

}
