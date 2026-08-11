public struct ArtifactResourceNamespaceID: Sendable, Hashable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Artifact resource namespace ID")
    self.rawValue = rawValue
  }

}
