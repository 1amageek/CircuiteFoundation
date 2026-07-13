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
    try self.init(legacyRawValue: container.decode(String.self))
  }

  init(legacyRawValue value: String) throws {
    let normalized = value.lowercased()
        .replacingOccurrences(of: "_", with: "-")
        .replacingOccurrences(of: " ", with: "-")
    let mapped: String
    switch normalized {
    case "timinglibrary", "timing-library": mapped = "timing.library"
    case "testpattern", "test-pattern": mapped = "test-pattern"
    case "powerintent", "power-intent": mapped = "power-intent"
    case "design-diff": mapped = "design-diff"
    case "ruledeck", "rule-deck": mapped = "rule-deck"
    default: mapped = normalized
    }
    try self.init(rawValue: mapped)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public static let constraints = Self(uncheckedRawValue: "constraints")
  public static let constraint = Self(uncheckedRawValue: "constraint")
  public static let designDiff = Self(uncheckedRawValue: "design-diff")
  public static let evidence = Self(uncheckedRawValue: "evidence")
  public static let input = Self(uncheckedRawValue: "input")
  public static let layout = Self(uncheckedRawValue: "layout")
  public static let log = Self(uncheckedRawValue: "log")
  public static let netlist = Self(uncheckedRawValue: "netlist")
  public static let parasitics = Self(uncheckedRawValue: "parasitics")
  public static let powerIntent = Self(uncheckedRawValue: "power-intent")
  public static let report = Self(uncheckedRawValue: "report")
  public static let release = Self(uncheckedRawValue: "release")
  public static let request = Self(uncheckedRawValue: "request")
  public static let ruleDeck = Self(uncheckedRawValue: "rule-deck")
  public static let rtl = Self(uncheckedRawValue: "rtl")
  public static let testPattern = Self(uncheckedRawValue: "test-pattern")
  public static let timingLibrary = Self(uncheckedRawValue: "timing-library")
  public static let model = Self(uncheckedRawValue: "model")
  public static let measurement = Self(uncheckedRawValue: "measurement")
  public static let other = Self(uncheckedRawValue: "other")
  public static let technology = Self(uncheckedRawValue: "technology")
  public static let waveform = Self(uncheckedRawValue: "waveform")
}
