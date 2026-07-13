public struct ArtifactKind: Sendable, Hashable, Codable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Artifact kind")
    self.rawValue = rawValue
  }

  private init(uncheckedRawValue value: String) {
    rawValue = value
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(rawValue: container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public static let constraints = Self(uncheckedRawValue: "constraints")
  public static let evidence = Self(uncheckedRawValue: "evidence")
  public static let layout = Self(uncheckedRawValue: "layout")
  public static let log = Self(uncheckedRawValue: "log")
  public static let netlist = Self(uncheckedRawValue: "netlist")
  public static let parasitics = Self(uncheckedRawValue: "parasitics")
  public static let report = Self(uncheckedRawValue: "report")
  public static let technology = Self(uncheckedRawValue: "technology")
  public static let waveform = Self(uncheckedRawValue: "waveform")
}
