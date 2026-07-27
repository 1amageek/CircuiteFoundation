public struct InteroperabilityExecutionPlan: Sendable, Hashable, Codable {
  public let backend: InteroperabilityBackend
  public let purpose: InteroperabilityBackendPurpose

  public init(
    backend: InteroperabilityBackend,
    purpose: InteroperabilityBackendPurpose
  ) throws(InteroperabilityContractError) {
    switch (backend, purpose) {
    case (.native, .primary):
      break
    case (.external, .compatibility), (.external, .oracle), (.external, .benchmark):
      break
    case (.native, _):
      throw .invalidBackendPurpose(
        "Native execution is the primary implementation and cannot be labeled as an external comparison."
      )
    case (.external, .primary):
      throw .invalidBackendPurpose(
        "External tools cannot be selected as the canonical primary implementation."
      )
    }
    self.backend = backend
    self.purpose = purpose
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      backend: container.decode(InteroperabilityBackend.self, forKey: .backend),
      purpose: container.decode(InteroperabilityBackendPurpose.self, forKey: .purpose)
    )
  }

  private enum CodingKeys: String, CodingKey {
    case backend
    case purpose
  }
}
