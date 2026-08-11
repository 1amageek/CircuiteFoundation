import CircuiteFoundation

extension ArtifactAccessIntent: Codable {
  private enum CodingKeys: String, CodingKey {
    case expectedReference
    case availability
    case operation
    case budget
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      expectedReference: container.decode(
        ArtifactReference.self,
        forKey: .expectedReference
      ),
      availability: container.decode(
        ArtifactAvailability.self,
        forKey: .availability
      ),
      operation: container.decode(ArtifactAccessOperation.self, forKey: .operation),
      budget: container.decode(ArtifactAccessBudget.self, forKey: .budget)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(expectedReference, forKey: .expectedReference)
    try container.encode(availability, forKey: .availability)
    try container.encode(operation, forKey: .operation)
    try container.encode(budget, forKey: .budget)
  }
}
