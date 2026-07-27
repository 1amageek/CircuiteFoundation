import Foundation

public struct InteroperabilityLoss: Sendable, Hashable, Codable {
  public let systemID: ExternalSystemID
  public let severity: InteroperabilityLossSeverity
  public let kind: InteroperabilityLossKind
  public let code: String
  public let message: String
  public let subject: DesignSubjectReference?
  public let sourcePath: String?

  public init(
    systemID: ExternalSystemID,
    severity: InteroperabilityLossSeverity,
    kind: InteroperabilityLossKind,
    code: String,
    message: String,
    subject: DesignSubjectReference? = nil,
    sourcePath: String? = nil
  ) throws {
    try TokenValidation.validate(code, kind: "Interoperability loss code")
    guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw InteroperabilityContractError.emptyLossMessage(code: code)
    }
    if let sourcePath {
      guard !sourcePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw InteroperabilityContractError.emptySourcePath(code: code)
      }
    }
    self.systemID = systemID
    self.severity = severity
    self.kind = kind
    self.code = code
    self.message = message
    self.subject = subject
    self.sourcePath = sourcePath
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

  private enum CodingKeys: String, CodingKey {
    case systemID
    case severity
    case kind
    case code
    case message
    case subject
    case sourcePath
  }
}
