public struct InteroperabilityReport: Sendable, Hashable, Codable {
  public let sourceSystem: ExternalSystemID
  public let targetSystem: ExternalSystemID
  public let direction: InteroperabilityDirection
  public let sourceDigest: ContentDigest?
  public let targetDigest: ContentDigest?
  public let mappedObjectCount: UInt64
  public let unmappedSemanticCount: UInt64
  public let losses: [InteroperabilityLoss]

  public var isSemanticallyComplete: Bool {
    unmappedSemanticCount == 0 && !losses.contains { $0.severity == .error }
  }

  public init(
    sourceSystem: ExternalSystemID,
    targetSystem: ExternalSystemID,
    direction: InteroperabilityDirection,
    sourceDigest: ContentDigest? = nil,
    targetDigest: ContentDigest? = nil,
    mappedObjectCount: UInt64,
    unmappedSemanticCount: UInt64,
    losses: [InteroperabilityLoss]
  ) {
    self.sourceSystem = sourceSystem
    self.targetSystem = targetSystem
    self.direction = direction
    self.sourceDigest = sourceDigest
    self.targetDigest = targetDigest
    self.mappedObjectCount = mappedObjectCount
    self.unmappedSemanticCount = unmappedSemanticCount
    self.losses = losses.sorted {
      if $0.severity != $1.severity { return $0.severity > $1.severity }
      if $0.code != $1.code { return $0.code < $1.code }
      return ($0.sourcePath ?? "") < ($1.sourcePath ?? "")
    }
  }

  public func requireSemanticCompleteness() throws(InteroperabilityContractError) {
    guard isSemanticallyComplete else { throw .semanticLoss(self) }
  }

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
      unmappedSemanticCount: try container.decode(UInt64.self, forKey: .unmappedSemanticCount),
      losses: try container.decode([InteroperabilityLoss].self, forKey: .losses)
    )
  }
}
