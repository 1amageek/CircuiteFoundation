public struct InteroperabilityLossKind: Sendable, Hashable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Interoperability loss kind")
    self.rawValue = rawValue
  }

  private init(uncheckedRawValue: String) {
    self.rawValue = uncheckedRawValue
  }

  public static let approximatedSemantics = Self(uncheckedRawValue: "approximated-semantics")
  public static let droppedProperty = Self(uncheckedRawValue: "dropped-property")
  public static let unsupportedConstruct = Self(uncheckedRawValue: "unsupported-construct")
  public static let unmappedObject = Self(uncheckedRawValue: "unmapped-object")
  public static let externalDiagnostic = Self(uncheckedRawValue: "external-diagnostic")
}
