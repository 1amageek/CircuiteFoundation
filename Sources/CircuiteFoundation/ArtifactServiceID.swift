public struct ArtifactServiceID: Sendable, Hashable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Artifact service ID")
    self.rawValue = rawValue
  }

}
