import CircuiteFoundation

extension InteroperabilityReport: Codable {
  private enum CodingKeys: String, CodingKey {
    case sourceSystem
    case targetSystem
    case direction
    case sourceDigest
    case targetDigest
    case mappedObjectCount
    case unmappedSemanticCount
    case losses
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      sourceSystem: try container.decode(ExternalSystemID.self, forKey: .sourceSystem),
      targetSystem: try container.decode(ExternalSystemID.self, forKey: .targetSystem),
      direction: try container.decode(InteroperabilityDirection.self, forKey: .direction),
      sourceDigest: try container.decodeIfPresent(ContentDigest.self, forKey: .sourceDigest),
      targetDigest: try container.decodeIfPresent(ContentDigest.self, forKey: .targetDigest),
      mappedObjectCount: try container.decode(UInt64.self, forKey: .mappedObjectCount),
      unmappedSemanticCount: try container.decode(
        UInt64.self,
        forKey: .unmappedSemanticCount
      ),
      losses: try container.decode([InteroperabilityLoss].self, forKey: .losses)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(sourceSystem, forKey: .sourceSystem)
    try container.encode(targetSystem, forKey: .targetSystem)
    try container.encode(direction, forKey: .direction)
    try container.encodeIfPresent(sourceDigest, forKey: .sourceDigest)
    try container.encodeIfPresent(targetDigest, forKey: .targetDigest)
    try container.encode(mappedObjectCount, forKey: .mappedObjectCount)
    try container.encode(unmappedSemanticCount, forKey: .unmappedSemanticCount)
    try container.encode(losses, forKey: .losses)
  }
}
