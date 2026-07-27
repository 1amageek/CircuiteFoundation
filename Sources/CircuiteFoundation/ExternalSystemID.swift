public struct ExternalSystemID: Sendable, Hashable, Codable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "External system identifier")
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

  public static let lsi = Self(uncheckedRawValue: "lsi")
  public static let googleXLS = Self(uncheckedRawValue: "google-xls")
  public static let openDB = Self(uncheckedRawValue: "open-db")
  public static let openROAD = Self(uncheckedRawValue: "open-road")
}
