public protocol DiagnosticReporting: Sendable {
  var diagnostics: [DesignDiagnostic] { get }
}
