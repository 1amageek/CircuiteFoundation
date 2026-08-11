import CircuiteFoundation

extension ContentDigestResult: Codable {
  private enum CodingKeys: String, CodingKey {
    case digest
    case totalByteCount
    case updateCount
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      digest: try container.decode(ContentDigest.self, forKey: .digest),
      totalByteCount: try container.decode(UInt64.self, forKey: .totalByteCount),
      updateCount: try container.decode(UInt64.self, forKey: .updateCount)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(digest, forKey: .digest)
    try container.encode(totalByteCount, forKey: .totalByteCount)
    try container.encode(updateCount, forKey: .updateCount)
  }
}
