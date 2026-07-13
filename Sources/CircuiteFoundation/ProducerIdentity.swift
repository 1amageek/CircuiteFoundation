public struct ProducerIdentity: Sendable, Hashable, Codable {
  public let kind: ProducerKind
  public let identifier: String
  public let version: String
  public let build: String?

  public init(
    kind: ProducerKind,
    identifier: String,
    version: String,
    build: String? = nil
  ) throws {
    try TokenValidation.validate(identifier, kind: "Producer identifier")
    try TokenValidation.validate(version, kind: "Producer version")
    if let build {
      try TokenValidation.validate(build, kind: "Producer build")
    }
    self.kind = kind
    self.identifier = identifier
    self.version = version
    self.build = build
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

  private enum CodingKeys: String, CodingKey {
    case kind
    case identifier
    case version
    case build
  }
}
