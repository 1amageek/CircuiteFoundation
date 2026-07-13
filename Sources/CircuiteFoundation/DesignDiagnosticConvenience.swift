public extension DesignDiagnostic {
  /// Convenience initializer for engine-owned diagnostic constants.
  init(
    severity: DiagnosticSeverity,
    code: String,
    message: String,
    entity: String? = nil,
    suggestedActions: [String] = []
  ) {
    self.init(
      code: DiagnosticCode.trusted(code),
      severity: severity,
      summary: message,
      detail: entity.map { "entity=\($0)" },
      suggestedActions: suggestedActions.map {
        SuggestedAction(code: $0, summary: $0)
      }
    )
  }
}
