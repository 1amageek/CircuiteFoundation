public enum ArtifactAvailability: Sendable, Hashable {
  case local(
    artifactID: ArtifactID,
    rootID: ArtifactRootID,
    relativePath: ArtifactRelativePath
  )
  case service(
    artifactID: ArtifactID,
    resource: ArtifactResourceReference
  )

  public var artifactID: ArtifactID {
    switch self {
    case .local(let artifactID, _, _), .service(let artifactID, _):
      artifactID
    }
  }
}
