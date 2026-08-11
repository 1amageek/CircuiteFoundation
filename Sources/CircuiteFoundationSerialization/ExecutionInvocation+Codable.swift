import CircuiteFoundation

extension ExecutionInvocation.Mode: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    guard let value = Self(rawValue: rawValue) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unknown execution invocation mode."
      )
    }
    self = value
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

extension ExecutionInvocation: Codable {
  private enum CodingKeys: String, CodingKey {
    case mode
    case entryPoint
    case executable
    case arguments
    case workingDirectory
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

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(mode, forKey: .mode)
    try container.encodeIfPresent(entryPoint, forKey: .entryPoint)
    try container.encodeIfPresent(executable, forKey: .executable)
    try container.encode(arguments, forKey: .arguments)
    try container.encodeIfPresent(workingDirectory, forKey: .workingDirectory)
  }
}
