public struct ArtifactFormat: Sendable, Hashable, Codable, RawRepresentable,
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

  public static let def = Self(rawValue: "def")
  public static let dspf = Self(rawValue: "dspf")
  public static let gdsii = Self(rawValue: "gdsii")
  public static let json = Self(rawValue: "json")
  public static let lef = Self(rawValue: "lef")
  public static let liberty = Self(rawValue: "liberty")
  public static let oasis = Self(rawValue: "oasis")
  public static let sdf = Self(rawValue: "sdf")
  public static let spef = Self(rawValue: "spef")
  public static let spice = Self(rawValue: "spice")
  public static let systemVerilog = Self(rawValue: "system-verilog")
  public static let verilog = Self(rawValue: "verilog")
  public static let vcd = Self(rawValue: "vcd")
}
