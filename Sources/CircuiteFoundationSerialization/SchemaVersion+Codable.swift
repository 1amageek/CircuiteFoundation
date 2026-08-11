import CircuiteFoundation

extension SchemaVersion: Codable {
  private enum CodingKeys: String, CodingKey {
    case major
    case minor
    case patch
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      major: try container.decode(UInt16.self, forKey: .major),
      minor: try container.decode(UInt16.self, forKey: .minor),
      patch: try container.decode(UInt16.self, forKey: .patch)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(major, forKey: .major)
    try container.encode(minor, forKey: .minor)
    try container.encode(patch, forKey: .patch)
  }
}
