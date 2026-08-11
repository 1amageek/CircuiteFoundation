import CircuiteFoundation

extension ArtifactAccessOperation: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    guard let value = Self(rawValue: rawValue) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unknown artifact access operation."
      )
    }
    self = value
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
