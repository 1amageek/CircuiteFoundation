public struct ProducerIdentity: Sendable, Hashable {
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

}
