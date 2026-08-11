public struct ProducerKind: Sendable, Hashable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Producer kind")
    self.rawValue = rawValue
  }

  private init(uncheckedRawValue value: String) {
    rawValue = value
  }

  public static let engine = Self(uncheckedRawValue: "engine")
  public static let library = Self(uncheckedRawValue: "library")
  public static let tool = Self(uncheckedRawValue: "tool")
}
