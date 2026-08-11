import CircuiteFoundation

extension ContentDigestSessionLimits: Codable {
  private enum CodingKeys: String, CodingKey {
    case maximumChunkByteCount
    case maximumTotalByteCount
    case maximumUpdateCount
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      maximumChunkByteCount: container.decode(UInt64.self, forKey: .maximumChunkByteCount),
      maximumTotalByteCount: container.decode(UInt64.self, forKey: .maximumTotalByteCount),
      maximumUpdateCount: container.decode(UInt64.self, forKey: .maximumUpdateCount)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(maximumChunkByteCount, forKey: .maximumChunkByteCount)
    try container.encode(maximumTotalByteCount, forKey: .maximumTotalByteCount)
    try container.encode(maximumUpdateCount, forKey: .maximumUpdateCount)
  }
}
