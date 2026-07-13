public struct DiagnosticCode: Sendable, Hashable, Codable {
  public let rawValue: String

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
}
