public struct DesignEntityReference: Sendable, Hashable {
  public let revision: DesignRevisionReference
  public let facetID: DesignFacetID
  public let kindID: DesignEntityKindID
  public let entityID: DesignEntityID

  public init(
    revision: DesignRevisionReference,
    facetID: DesignFacetID,
    kindID: DesignEntityKindID,
    entityID: DesignEntityID
  ) {
    self.revision = revision
    self.facetID = facetID
    self.kindID = kindID
    self.entityID = entityID
  }
}
