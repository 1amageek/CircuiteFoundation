public struct InteroperabilityLossKind: Sendable, Hashable, Codable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Interoperability loss kind")
    self.rawValue = rawValue
  }

  private init(uncheckedRawValue: String) {
    self.rawValue = uncheckedRawValue
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(rawValue: container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public static let approximatedSemantics = Self(uncheckedRawValue: "approximated-semantics")
  public static let droppedProperty = Self(uncheckedRawValue: "dropped-property")
  public static let unsupportedConstruct = Self(uncheckedRawValue: "unsupported-construct")
  public static let unmappedObject = Self(uncheckedRawValue: "unmapped-object")
  public static let externalDiagnostic = Self(uncheckedRawValue: "external-diagnostic")
}
