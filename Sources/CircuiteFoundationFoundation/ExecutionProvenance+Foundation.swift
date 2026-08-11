import CircuiteFoundation
import Foundation

public extension ExecutionTimestamp {
  init(_ date: Date) throws(ExecutionProvenanceError) {
    try self.init(secondsSinceUnixEpoch: date.timeIntervalSince1970)
  }

  var foundationDate: Date {
    Date(timeIntervalSince1970: secondsSinceUnixEpoch)
  }
}

public extension ExecutionProvenance {
  init(
    producer: ProducerIdentity,
    supportingTools: [ProducerIdentity] = [],
    inputs: [ArtifactReference] = [],
    invocation: ExecutionInvocation? = nil,
    environment: ExecutionEnvironmentFingerprint? = nil,
    configurationDigest: ContentDigest? = nil,
    inputDesignRevision: DesignRevisionReference? = nil,
    outputDesignRevision: DesignRevisionReference? = nil,
    randomSeed: UInt64? = nil,
    startedAt: Date,
    completedAt: Date
  ) throws(ExecutionProvenanceError) {
    try self.init(
      producer: producer,
      supportingTools: supportingTools,
      inputs: inputs,
      invocation: invocation,
      environment: environment,
      configurationDigest: configurationDigest,
      inputDesignRevision: inputDesignRevision,
      outputDesignRevision: outputDesignRevision,
      randomSeed: randomSeed,
      startedAt: ExecutionTimestamp(startedAt),
      completedAt: ExecutionTimestamp(completedAt)
    )
  }
}
