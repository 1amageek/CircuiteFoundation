import CircuiteFoundation

extension InteroperabilityExecutionPlan: Codable {
  private enum CodingKeys: String, CodingKey {
    case backend
    case purpose
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      backend: container.decode(InteroperabilityBackend.self, forKey: .backend),
      purpose: container.decode(InteroperabilityBackendPurpose.self, forKey: .purpose)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(backend, forKey: .backend)
    try container.encode(purpose, forKey: .purpose)
  }
}
