import Foundation

public enum ExecutionProvenanceError: Error, Sendable, Equatable, LocalizedError {
  case completionPrecedesStart(startedAt: Date, completedAt: Date)
  case nonFiniteTimestamp(kind: String, value: Double)

  public var errorDescription: String? {
    switch self {
    case .completionPrecedesStart(let startedAt, let completedAt):
      "Execution completed at \(completedAt) before it started at \(startedAt)."
    case .nonFiniteTimestamp(let kind, let value):
      "\(kind) timestamp must be finite; received \(value)."
    }
  }
}
