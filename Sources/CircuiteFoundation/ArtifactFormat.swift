public struct ArtifactFormat: Sendable, Hashable, Codable {
  public let rawValue: String

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Artifact format")
    self.rawValue = rawValue
  }

  private init(uncheckedRawValue value: String) {
    rawValue = value
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(legacyRawValue: container.decode(String.self))
  }

  init(legacyRawValue value: String) throws {
    let normalized = value.lowercased()
        .replacingOccurrences(of: "_", with: "-")
        .replacingOccurrences(of: " ", with: "-")
    let mapped: String
    switch normalized {
    case "json": mapped = "json"
    case "systemverilog", "system-verilog": mapped = "system-verilog"
    case "gdsii", "gds-ii": mapped = "gdsii"
    case "oas", "oasis": mapped = "oasis"
    case "spice", "sp": mapped = "spice"
    default: mapped = normalized
    }
    try self.init(rawValue: mapped)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public static let def = Self(uncheckedRawValue: "def")
  public static let dspf = Self(uncheckedRawValue: "dspf")
  public static let cpf = Self(uncheckedRawValue: "cpf")
  public static let csv = Self(uncheckedRawValue: "csv")
  public static let fst = Self(uncheckedRawValue: "fst")
  public static let gdsii = Self(uncheckedRawValue: "gdsii")
  public static let json = Self(uncheckedRawValue: "json")
  public static let lef = Self(uncheckedRawValue: "lef")
  public static let liberty = Self(uncheckedRawValue: "liberty")
  public static let oasis = Self(uncheckedRawValue: "oasis")
  public static let raw = Self(uncheckedRawValue: "raw")
  public static let sdf = Self(uncheckedRawValue: "sdf")
  public static let spef = Self(uncheckedRawValue: "spef")
  public static let spice = Self(uncheckedRawValue: "spice")
  public static let sdc = Self(uncheckedRawValue: "sdc")
  public static let stil = Self(uncheckedRawValue: "stil")
  public static let systemVerilog = Self(uncheckedRawValue: "system-verilog")
  public static let text = Self(uncheckedRawValue: "text")
  public static let unknown = Self(uncheckedRawValue: "unknown")
  public static let upf = Self(uncheckedRawValue: "upf")
  public static let verilog = Self(uncheckedRawValue: "verilog")
  public static let vcd = Self(uncheckedRawValue: "vcd")
  public static let wgl = Self(uncheckedRawValue: "wgl")
}
