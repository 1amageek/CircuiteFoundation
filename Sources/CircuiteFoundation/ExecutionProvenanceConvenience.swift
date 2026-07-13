import Foundation

public extension ExecutionProvenance {
  init(
    engineID: String,
    implementationID: String,
    implementationVersion: String,
    startedAt: Date,
    completedAt: Date
  ) throws {
    try self.init(
      producer: ProducerIdentity(
        kind: .engine,
        identifier: engineID,
        version: implementationVersion,
        build: implementationID
      ),
      invocation: ExecutionInvocation.inProcess(entryPoint: implementationID),
      startedAt: startedAt,
      completedAt: completedAt
    )
  }
}
