public struct ExternalSystemID: Sendable, Hashable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "External system identifier")
    self.rawValue = rawValue
  }

  private init(uncheckedRawValue: String) {
    self.rawValue = uncheckedRawValue
  }

  public static let lsi = Self(uncheckedRawValue: "lsi")
  public static let googleXLS = Self(uncheckedRawValue: "google-xls")
  public static let openDB = Self(uncheckedRawValue: "open-db")
  public static let openROAD = Self(uncheckedRawValue: "open-road")
}
