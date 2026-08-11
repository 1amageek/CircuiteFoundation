import CircuiteFoundation

extension ArtifactAvailability: Codable {
  private enum Kind: String, Codable {
    case local
    case service
  }

  private enum CodingKeys: String, CodingKey {
    case kind
    case artifactID
    case rootID
    case relativePath
    case resource
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let artifactID = try container.decode(ArtifactID.self, forKey: .artifactID)
    switch try container.decode(Kind.self, forKey: .kind) {
    case .local:
      self = .local(
        artifactID: artifactID,
        rootID: try container.decode(ArtifactRootID.self, forKey: .rootID),
        relativePath: try container.decode(
          ArtifactRelativePath.self,
          forKey: .relativePath
        )
      )
    case .service:
      self = .service(
        artifactID: artifactID,
        resource: try container.decode(
          ArtifactResourceReference.self,
          forKey: .resource
        )
      )
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .local(let artifactID, let rootID, let relativePath):
      try container.encode(Kind.local, forKey: .kind)
      try container.encode(artifactID, forKey: .artifactID)
      try container.encode(rootID, forKey: .rootID)
      try container.encode(relativePath, forKey: .relativePath)
    case .service(let artifactID, let resource):
      try container.encode(Kind.service, forKey: .kind)
      try container.encode(artifactID, forKey: .artifactID)
      try container.encode(resource, forKey: .resource)
    }
  }
}
