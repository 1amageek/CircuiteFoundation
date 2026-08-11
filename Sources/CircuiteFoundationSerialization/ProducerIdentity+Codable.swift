import CircuiteFoundation

extension ProducerIdentity: Codable {
  private enum CodingKeys: String, CodingKey {
    case kind
    case identifier
    case version
    case build
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      kind: container.decode(ProducerKind.self, forKey: .kind),
      identifier: container.decode(String.self, forKey: .identifier),
      version: container.decode(String.self, forKey: .version),
      build: container.decodeIfPresent(String.self, forKey: .build)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(kind, forKey: .kind)
    try container.encode(identifier, forKey: .identifier)
    try container.encode(version, forKey: .version)
    try container.encodeIfPresent(build, forKey: .build)
  }
}
