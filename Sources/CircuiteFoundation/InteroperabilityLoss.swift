public struct InteroperabilityLoss: Sendable, Hashable {
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
    guard !message.isEmpty, !message.allSatisfy({ $0.isWhitespace }) else {
      throw InteroperabilityContractError.emptyLossMessage(code: code)
    }
    if let sourcePath {
      guard !sourcePath.isEmpty, !sourcePath.allSatisfy({ $0.isWhitespace }) else {
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

}
