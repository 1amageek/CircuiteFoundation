import Foundation

public enum ExecutionProvenanceError: Error, Sendable, Equatable, LocalizedError {
  case completionPrecedesStart(startedAt: Date, completedAt: Date)

  public var errorDescription: String? {
    switch self {
    case .completionPrecedesStart(let startedAt, let completedAt):
      "Execution completed at \(completedAt) before it started at \(startedAt)."
    }
  }
}
