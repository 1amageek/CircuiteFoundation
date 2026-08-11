import CircuiteFoundation

extension ArtifactReadPageRequest: Codable {
  private enum CodingKeys: String, CodingKey {
    case offset
    case maximumByteCount
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      offset: container.decode(UInt64.self, forKey: .offset),
      maximumByteCount: container.decode(UInt64.self, forKey: .maximumByteCount)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(offset, forKey: .offset)
    try container.encode(maximumByteCount, forKey: .maximumByteCount)
  }
}
