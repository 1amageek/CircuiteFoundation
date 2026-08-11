public struct ArtifactResourceID: Sendable, Hashable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Artifact resource ID")
    self.rawValue = rawValue
  }

}
