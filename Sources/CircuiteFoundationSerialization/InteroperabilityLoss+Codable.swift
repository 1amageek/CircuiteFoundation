import CircuiteFoundation

extension InteroperabilityLoss: Codable {
  private enum CodingKeys: String, CodingKey {
    case systemID
    case severity
    case kind
    case code
    case message
    case subject
    case sourcePath
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      systemID: container.decode(ExternalSystemID.self, forKey: .systemID),
      severity: container.decode(InteroperabilityLossSeverity.self, forKey: .severity),
      kind: container.decode(InteroperabilityLossKind.self, forKey: .kind),
      code: container.decode(String.self, forKey: .code),
      message: container.decode(String.self, forKey: .message),
      subject: container.decodeIfPresent(DesignSubjectReference.self, forKey: .subject),
      sourcePath: container.decodeIfPresent(String.self, forKey: .sourcePath)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(systemID, forKey: .systemID)
    try container.encode(severity, forKey: .severity)
    try container.encode(kind, forKey: .kind)
    try container.encode(code, forKey: .code)
    try container.encode(message, forKey: .message)
    try container.encodeIfPresent(subject, forKey: .subject)
    try container.encodeIfPresent(sourcePath, forKey: .sourcePath)
  }
}
