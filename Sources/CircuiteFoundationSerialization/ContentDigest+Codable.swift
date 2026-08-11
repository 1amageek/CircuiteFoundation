import CircuiteFoundation

extension ContentDigest: Codable {
  private enum CodingKeys: String, CodingKey {
    case algorithm
    case hexadecimalValue
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      algorithm: container.decode(ContentDigestAlgorithm.self, forKey: .algorithm),
      hexadecimalValue: container.decode(String.self, forKey: .hexadecimalValue)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(algorithm, forKey: .algorithm)
    try container.encode(hexadecimalValue, forKey: .hexadecimalValue)
  }
}
