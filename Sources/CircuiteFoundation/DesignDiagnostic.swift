public struct DesignDiagnostic: Sendable, Hashable, Codable {
  public let code: DiagnosticCode
  public let severity: DiagnosticSeverity
  public let summary: String
  public let detail: String?
  public let subject: DesignObjectReference?
  public let artifactID: ArtifactID?
  public let suggestedActions: [SuggestedAction]

  public init(
    code: DiagnosticCode,
    severity: DiagnosticSeverity,
    summary: String,
    detail: String? = nil,
    subject: DesignObjectReference? = nil,
    artifactID: ArtifactID? = nil,
    suggestedActions: [SuggestedAction] = []
  ) {
    self.code = code
    self.severity = severity
    self.summary = summary
    self.detail = detail
    self.subject = subject
    self.artifactID = artifactID
    self.suggestedActions = suggestedActions
  }
}
