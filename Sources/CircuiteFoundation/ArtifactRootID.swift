public struct ArtifactRootID: Sendable, Hashable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Artifact root ID")
    self.rawValue = rawValue
  }

}
