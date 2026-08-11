import CircuiteFoundation

extension ExecutionProvenance: Codable {
  private enum CodingKeys: String, CodingKey {
    case producer
    case supportingTools
    case inputs
    case invocation
    case environment
    case configurationDigest
    case inputDesignRevision
    case outputDesignRevision
    case randomSeed
    case startedAt
    case completedAt
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      producer: container.decode(ProducerIdentity.self, forKey: .producer),
      supportingTools: container.decode([ProducerIdentity].self, forKey: .supportingTools),
      inputs: container.decode([ArtifactReference].self, forKey: .inputs),
      invocation: container.decodeIfPresent(ExecutionInvocation.self, forKey: .invocation),
      environment: container.decodeIfPresent(
        ExecutionEnvironmentFingerprint.self,
        forKey: .environment
      ),
      configurationDigest: container.decodeIfPresent(
        ContentDigest.self,
        forKey: .configurationDigest
      ),
      inputDesignRevision: container.decodeIfPresent(
        DesignRevisionReference.self,
        forKey: .inputDesignRevision
      ),
      outputDesignRevision: container.decodeIfPresent(
        DesignRevisionReference.self,
        forKey: .outputDesignRevision
      ),
      randomSeed: container.decodeIfPresent(UInt64.self, forKey: .randomSeed),
      startedAt: container.decode(ExecutionTimestamp.self, forKey: .startedAt),
      completedAt: container.decode(ExecutionTimestamp.self, forKey: .completedAt)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(producer, forKey: .producer)
    try container.encode(supportingTools, forKey: .supportingTools)
    try container.encode(inputs, forKey: .inputs)
    try container.encodeIfPresent(invocation, forKey: .invocation)
    try container.encodeIfPresent(environment, forKey: .environment)
    try container.encodeIfPresent(configurationDigest, forKey: .configurationDigest)
    try container.encodeIfPresent(inputDesignRevision, forKey: .inputDesignRevision)
    try container.encodeIfPresent(outputDesignRevision, forKey: .outputDesignRevision)
    try container.encodeIfPresent(randomSeed, forKey: .randomSeed)
    try container.encode(startedAt, forKey: .startedAt)
    try container.encode(completedAt, forKey: .completedAt)
  }
}
