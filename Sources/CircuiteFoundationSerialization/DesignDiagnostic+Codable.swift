import CircuiteFoundation

extension DesignDiagnostic: Codable {
  private enum CodingKeys: String, CodingKey {
    case code
    case severity
    case summary
    case detail
    case subject
    case artifactID
    case suggestedActions
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      code: try container.decode(DiagnosticCode.self, forKey: .code),
      severity: try container.decode(DiagnosticSeverity.self, forKey: .severity),
      summary: try container.decode(String.self, forKey: .summary),
      detail: try container.decodeIfPresent(String.self, forKey: .detail),
      subject: try container.decodeIfPresent(
        DesignSubjectReference.self,
        forKey: .subject
      ),
      artifactID: try container.decodeIfPresent(ArtifactID.self, forKey: .artifactID),
      suggestedActions: try container.decode(
        [SuggestedAction].self,
        forKey: .suggestedActions
      )
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(code, forKey: .code)
    try container.encode(severity, forKey: .severity)
    try container.encode(summary, forKey: .summary)
    try container.encodeIfPresent(detail, forKey: .detail)
    try container.encodeIfPresent(subject, forKey: .subject)
    try container.encodeIfPresent(artifactID, forKey: .artifactID)
    try container.encode(suggestedActions, forKey: .suggestedActions)
  }
}
