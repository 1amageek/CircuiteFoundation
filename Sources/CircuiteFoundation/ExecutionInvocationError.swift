import Foundation

public enum ExecutionInvocationError: Error, Sendable, Equatable, LocalizedError {
  case missingEntryPoint
  case missingExecutable
  case invalidInProcessFields
  case invalidExternalProcessFields
  case argumentContainsControlCharacter(String)

  public var errorDescription: String? {
    switch self {
    case .missingEntryPoint:
      "An in-process invocation requires an entry point."
    case .missingExecutable:
      "An external-process invocation requires an executable."
    case .invalidInProcessFields:
      "An in-process invocation cannot contain external-process fields."
    case .invalidExternalProcessFields:
      "An external-process invocation cannot contain an in-process entry point."
    case .argumentContainsControlCharacter(let argument):
      "An execution argument contains a control character: \(argument)"
    }
  }
}
