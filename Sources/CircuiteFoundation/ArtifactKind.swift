public struct ArtifactKind: Sendable, Hashable, Codable, RawRepresentable,
  ExpressibleByStringLiteral
{
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.init(rawValue: value)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    rawValue = try container.decode(String.self)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public static let constraints = Self(rawValue: "constraints")
  public static let evidence = Self(rawValue: "evidence")
  public static let layout = Self(rawValue: "layout")
  public static let log = Self(rawValue: "log")
  public static let netlist = Self(rawValue: "netlist")
  public static let parasitics = Self(rawValue: "parasitics")
  public static let report = Self(rawValue: "report")
  public static let technology = Self(rawValue: "technology")
  public static let waveform = Self(rawValue: "waveform")
}
