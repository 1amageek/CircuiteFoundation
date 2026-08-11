public enum ExecutionProvenanceError: Error, Sendable, Equatable {
  case completionPrecedesStart(
    startedAt: ExecutionTimestamp,
    completedAt: ExecutionTimestamp
  )
  case nonFiniteTimestamp(kind: String, value: Double)
}
