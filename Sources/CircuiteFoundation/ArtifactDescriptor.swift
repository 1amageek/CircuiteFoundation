public struct ArtifactDescriptor: Sendable, Hashable {
  public let role: ArtifactRole
  public let kind: ArtifactKind
  public let format: ArtifactFormat

  public init(
    role: ArtifactRole,
    kind: ArtifactKind,
    format: ArtifactFormat
  ) {
    self.role = role
    self.kind = kind
    self.format = format
  }
}
