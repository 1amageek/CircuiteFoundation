import Foundation

/// Describes how an engine execution was invoked without exposing raw
/// environment variables or process state.
public struct ExecutionInvocation: Sendable, Hashable, Codable {
  public enum Mode: String, Sendable, Hashable, Codable {
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
        guard !argument.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else {
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

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      mode: container.decode(Mode.self, forKey: .mode),
      entryPoint: container.decodeIfPresent(String.self, forKey: .entryPoint),
      executable: container.decodeIfPresent(String.self, forKey: .executable),
      arguments: container.decode([String].self, forKey: .arguments),
      workingDirectory: container.decodeIfPresent(String.self, forKey: .workingDirectory)
    )
  }

  private enum CodingKeys: String, CodingKey {
    case mode
    case entryPoint
    case executable
    case arguments
    case workingDirectory
  }
}
