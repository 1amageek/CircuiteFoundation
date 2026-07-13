public struct DiagnosticCode: Sendable, Hashable, Codable {
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

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(rawValue: container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  private init(uncheckedRawValue value: String) {
    rawValue = value
  }
}
