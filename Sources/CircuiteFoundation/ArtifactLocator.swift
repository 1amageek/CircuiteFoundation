public struct ArtifactLocator: Sendable, Hashable, Codable {
  public let location: ArtifactLocation
  public let kind: ArtifactKind
  public let format: ArtifactFormat

  public init(
    location: ArtifactLocation,
    kind: ArtifactKind,
    format: ArtifactFormat
  ) {
    self.location = location
    self.kind = kind
    self.format = format
  }
}
