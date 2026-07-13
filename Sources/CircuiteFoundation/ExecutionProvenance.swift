import Foundation

public struct ExecutionProvenance: Sendable, Hashable, Codable {
  public let producer: ProducerIdentity
  public let supportingTools: [ProducerIdentity]
  public let inputs: [ArtifactReference]
  public let invocation: ExecutionInvocation?
  public let environment: ExecutionEnvironmentFingerprint?
  public let configurationDigest: ContentDigest?
  public let designRevision: ContentDigest?
  public let randomSeed: UInt64?
  public let startedAt: Date
  public let completedAt: Date

  public init(
    producer: ProducerIdentity,
    supportingTools: [ProducerIdentity] = [],
    inputs: [ArtifactReference] = [],
    invocation: ExecutionInvocation? = nil,
    environment: ExecutionEnvironmentFingerprint? = nil,
    configurationDigest: ContentDigest? = nil,
    designRevision: ContentDigest? = nil,
    randomSeed: UInt64? = nil,
    startedAt: Date,
    completedAt: Date
  ) throws {
    let startInterval = startedAt.timeIntervalSinceReferenceDate
    let completionInterval = completedAt.timeIntervalSinceReferenceDate
    guard startInterval.isFinite else {
      throw ExecutionProvenanceError.nonFiniteTimestamp(
        kind: "Start",
        value: startInterval
      )
    }
    guard completionInterval.isFinite else {
      throw ExecutionProvenanceError.nonFiniteTimestamp(
        kind: "Completion",
        value: completionInterval
      )
    }
    guard completedAt >= startedAt else {
      throw ExecutionProvenanceError.completionPrecedesStart(
        startedAt: startedAt,
        completedAt: completedAt
      )
    }
    self.producer = producer
    self.supportingTools = supportingTools
    self.inputs = inputs
    self.invocation = invocation
    self.environment = environment
    self.configurationDigest = configurationDigest
    self.designRevision = designRevision
    self.randomSeed = randomSeed
    self.startedAt = startedAt
    self.completedAt = completedAt
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      producer: container.decode(ProducerIdentity.self, forKey: .producer),
      supportingTools: container.decodeIfPresent([ProducerIdentity].self, forKey: .supportingTools) ?? [],
      inputs: container.decodeIfPresent([ArtifactReference].self, forKey: .inputs) ?? [],
      invocation: container.decodeIfPresent(ExecutionInvocation.self, forKey: .invocation),
      environment: container.decodeIfPresent(
        ExecutionEnvironmentFingerprint.self, forKey: .environment),
      configurationDigest: container.decodeIfPresent(
        ContentDigest.self, forKey: .configurationDigest),
      designRevision: container.decodeIfPresent(ContentDigest.self, forKey: .designRevision),
      randomSeed: container.decodeIfPresent(UInt64.self, forKey: .randomSeed),
      startedAt: container.decode(Date.self, forKey: .startedAt),
      completedAt: container.decode(Date.self, forKey: .completedAt)
    )
  }

  private enum CodingKeys: String, CodingKey {
    case producer
    case supportingTools
    case inputs
    case invocation
    case environment
    case configurationDigest
    case designRevision
    case randomSeed
    case startedAt
    case completedAt
  }
}
