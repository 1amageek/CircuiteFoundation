public enum InteroperabilityLossSeverity: String, Sendable, Hashable, Codable, Comparable {
  case information
  case warning
  case error

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rank < rhs.rank
  }

  private var rank: Int {
    switch self {
    case .information: 0
    case .warning: 1
    case .error: 2
    }
  }
}
