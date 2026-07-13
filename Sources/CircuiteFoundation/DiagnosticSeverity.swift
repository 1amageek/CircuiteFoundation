public enum DiagnosticSeverity: Int, Sendable, Hashable, Codable, CaseIterable, Comparable {
  case information = 0
  case warning = 1
  case error = 2

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
