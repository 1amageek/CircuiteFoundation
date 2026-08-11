public struct DesignEntityKindID: Sendable, Hashable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Design entity-kind identifier")
    self.rawValue = rawValue
  }

}
