public struct ExecutionProvenance: Sendable, Hashable {
  public let producer: ProducerIdentity
  public let supportingTools: [ProducerIdentity]
  public let inputs: [ArtifactReference]
  public let invocation: ExecutionInvocation?
  public let environment: ExecutionEnvironmentFingerprint?
  public let configurationDigest: ContentDigest?
  public let inputDesignRevision: DesignRevisionReference?
  public let outputDesignRevision: DesignRevisionReference?
  public let randomSeed: UInt64?
  public let startedAt: ExecutionTimestamp
  public let completedAt: ExecutionTimestamp

  public init(
    producer: ProducerIdentity,
    supportingTools: [ProducerIdentity] = [],
    inputs: [ArtifactReference] = [],
    invocation: ExecutionInvocation? = nil,
    environment: ExecutionEnvironmentFingerprint? = nil,
    configurationDigest: ContentDigest? = nil,
    inputDesignRevision: DesignRevisionReference? = nil,
    outputDesignRevision: DesignRevisionReference? = nil,
    randomSeed: UInt64? = nil,
    startedAt: ExecutionTimestamp,
    completedAt: ExecutionTimestamp
  ) throws(ExecutionProvenanceError) {
    guard completedAt >= startedAt else {
      throw .completionPrecedesStart(startedAt: startedAt, completedAt: completedAt)
    }
    self.producer = producer
    self.supportingTools = supportingTools
    self.inputs = inputs
    self.invocation = invocation
    self.environment = environment
    self.configurationDigest = configurationDigest
    self.inputDesignRevision = inputDesignRevision
    self.outputDesignRevision = outputDesignRevision
    self.randomSeed = randomSeed
    self.startedAt = startedAt
    self.completedAt = completedAt
  }

}
