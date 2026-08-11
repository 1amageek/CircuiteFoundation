public struct DesignFacetID: Sendable, Hashable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Design facet identifier")
    self.rawValue = rawValue
  }

}
