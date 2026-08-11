import CircuiteFoundation

extension ArtifactResourceReference: Codable {
  private enum CodingKeys: String, CodingKey {
    case serviceID
    case namespaceID
    case resourceID
    case generation
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      serviceID: container.decode(ArtifactServiceID.self, forKey: .serviceID),
      namespaceID: container.decode(
        ArtifactResourceNamespaceID.self,
        forKey: .namespaceID
      ),
      resourceID: container.decode(ArtifactResourceID.self, forKey: .resourceID),
      generation: container.decode(UInt64.self, forKey: .generation)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(serviceID, forKey: .serviceID)
    try container.encode(namespaceID, forKey: .namespaceID)
    try container.encode(resourceID, forKey: .resourceID)
    try container.encode(generation, forKey: .generation)
  }
}
