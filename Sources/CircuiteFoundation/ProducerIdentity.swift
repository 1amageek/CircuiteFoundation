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
  ) {
    self.kind = kind
    self.identifier = identifier
    self.version = version
    self.build = build
  }
}
