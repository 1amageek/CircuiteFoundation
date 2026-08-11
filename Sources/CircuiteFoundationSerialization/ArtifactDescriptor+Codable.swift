import CircuiteFoundation

extension ArtifactDescriptor: Codable {
  private enum CodingKeys: String, CodingKey {
    case role
    case kind
    case format
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      role: try container.decode(ArtifactRole.self, forKey: .role),
      kind: try container.decode(ArtifactKind.self, forKey: .kind),
      format: try container.decode(ArtifactFormat.self, forKey: .format)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(role, forKey: .role)
    try container.encode(kind, forKey: .kind)
    try container.encode(format, forKey: .format)
  }
}
