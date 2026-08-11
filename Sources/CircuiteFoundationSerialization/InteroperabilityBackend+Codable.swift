import CircuiteFoundation

extension InteroperabilityBackend: Codable {
  private enum Kind: String, Codable {
    case native
    case external
  }

  private enum CodingKeys: String, CodingKey {
    case kind
    case externalSystem
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Kind.self, forKey: .kind) {
    case .native:
      self = .native
    case .external:
      self = .external(
        try container.decode(ExternalSystemID.self, forKey: .externalSystem)
      )
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .native:
      try container.encode(Kind.native, forKey: .kind)
    case .external(let systemID):
      try container.encode(Kind.external, forKey: .kind)
      try container.encode(systemID, forKey: .externalSystem)
    }
  }
}
