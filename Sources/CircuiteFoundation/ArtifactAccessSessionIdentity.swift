public struct ArtifactAccessSessionIdentity: Sendable, Hashable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Artifact access session identity")
    self.rawValue = rawValue
  }

}
