import CircuiteFoundation

extension ArtifactReference: Codable {
  private enum CodingKeys: String, CodingKey {
    case id
    case descriptor
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      id: try container.decode(ArtifactID.self, forKey: .id),
      descriptor: try container.decode(ArtifactDescriptor.self, forKey: .descriptor)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(descriptor, forKey: .descriptor)
  }
}
