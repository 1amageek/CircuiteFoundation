public struct DiagnosticCode: Sendable, Hashable {
  public let rawValue: String

  /// Creates a code from a producer-controlled token. Producers should use
  /// `init(rawValue:)` when validating external input; this entry point keeps
  /// already-validated diagnostic constants non-throwing at emission sites.
  public static func trusted(_ rawValue: String) -> Self {
    Self(uncheckedRawValue: rawValue)
  }

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Diagnostic code")
    self.rawValue = rawValue
  }

  private init(uncheckedRawValue value: String) {
    rawValue = value
  }
}
