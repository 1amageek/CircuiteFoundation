import CircuiteFoundation

extension SchemaVersionRange: Codable {
  private enum CodingKeys: String, CodingKey {
    case lowerBound
    case upperBound
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      lowerBound: container.decode(SchemaVersion.self, forKey: .lowerBound),
      upperBound: container.decode(SchemaVersion.self, forKey: .upperBound)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(lowerBound, forKey: .lowerBound)
    try container.encode(upperBound, forKey: .upperBound)
  }
}
