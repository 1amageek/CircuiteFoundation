import Foundation

public enum InteroperabilityContractError: Error, Sendable, Hashable, LocalizedError {
  case emptyLossMessage(code: String)
  case emptySourcePath(code: String)
  case invalidBackendPurpose(String)
  case semanticLoss(InteroperabilityReport)

  public var errorDescription: String? {
    switch self {
    case .emptyLossMessage(let code):
      return "Interoperability loss \(code) has an empty message."
    case .emptySourcePath(let code):
      return "Interoperability loss \(code) has an empty source path."
    case .invalidBackendPurpose(let reason):
      return reason
    case .semanticLoss(let report):
      return "Interoperability conversion is incomplete with \(report.unmappedSemanticCount) unmapped semantic items."
    }
  }
}
