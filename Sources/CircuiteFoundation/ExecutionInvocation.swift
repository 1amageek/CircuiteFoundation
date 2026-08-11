/// Describes how an engine execution was invoked without exposing raw
/// environment variables or process state.
public struct ExecutionInvocation: Sendable, Hashable {
  public enum Mode: String, Sendable, Hashable {
    case inProcess
    case externalProcess
  }

  public let mode: Mode
  public let entryPoint: String?
  public let executable: String?
  public let arguments: [String]
  public let workingDirectory: String?

  public static func inProcess(entryPoint: String) throws -> Self {
    try Self(
      mode: .inProcess,
      entryPoint: entryPoint,
      executable: nil,
      arguments: [],
      workingDirectory: nil
    )
  }

  public static func externalProcess(
    executable: String,
    arguments: [String] = [],
    workingDirectory: String? = nil
  ) throws -> Self {
    try Self(
      mode: .externalProcess,
      entryPoint: nil,
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory
    )
  }

  public init(
    mode: Mode,
    entryPoint: String?,
    executable: String?,
    arguments: [String],
    workingDirectory: String?
  ) throws {
    switch mode {
    case .inProcess:
      guard let entryPoint else {
        throw ExecutionInvocationError.missingEntryPoint
      }
      try TokenValidation.validate(entryPoint, kind: "Execution entry point")
      guard executable == nil, arguments.isEmpty, workingDirectory == nil else {
        throw ExecutionInvocationError.invalidInProcessFields
      }
    case .externalProcess:
      guard let executable else {
        throw ExecutionInvocationError.missingExecutable
      }
      try TokenValidation.validate(executable, kind: "Execution executable")
      guard entryPoint == nil else {
        throw ExecutionInvocationError.invalidExternalProcessFields
      }
      for argument in arguments {
        guard !TokenValidation.containsControlCharacter(argument) else {
          throw ExecutionInvocationError.argumentContainsControlCharacter(argument)
        }
      }
      if let workingDirectory {
        try TokenValidation.validate(workingDirectory, kind: "Execution working directory")
      }
    }

    self.mode = mode
    self.entryPoint = entryPoint
    self.executable = executable
    self.arguments = arguments
    self.workingDirectory = workingDirectory
  }

}
