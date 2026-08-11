public struct InteroperabilityReport: Sendable, Hashable {
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

}
