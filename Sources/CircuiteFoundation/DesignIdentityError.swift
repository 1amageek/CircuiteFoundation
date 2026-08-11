public enum DesignIdentityError: Error, Sendable, Equatable {
  case invalidCanonicalEncoding(kind: String, value: String)
  case zeroIdentity(kind: String)

  public var errorDescription: String? {
    switch self {
    case .invalidCanonicalEncoding(let kind, let value):
      return "\(kind) has a non-canonical hexadecimal encoding: \(value)"
    case .zeroIdentity(let kind):
      return "\(kind) must not be zero."
    }
  }
}
