public struct ContentDigest: Sendable, Hashable, Codable {
  public let algorithm: ContentDigestAlgorithm
  public let hexadecimalValue: String

  public init(
    algorithm: ContentDigestAlgorithm,
    hexadecimalValue: String
  ) throws {
    let normalizedValue = hexadecimalValue.lowercased()
    guard !normalizedValue.isEmpty else {
      throw ContentDigestError.emptyHexadecimalValue
    }
    guard normalizedValue.allSatisfy(\.isHexDigit) else {
      throw ContentDigestError.invalidHexadecimalValue(hexadecimalValue)
    }
    guard normalizedValue.count.isMultiple(of: 2) else {
      throw ContentDigestError.incompleteByte(hexadecimalValue)
    }
    if algorithm == .sha256, normalizedValue.count != 64 {
      throw ContentDigestError.invalidLength(
        algorithm: algorithm,
        actual: normalizedValue.count,
        expected: 64
      )
    }
    self.algorithm = algorithm
    self.hexadecimalValue = normalizedValue
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let algorithm = try container.decode(ContentDigestAlgorithm.self, forKey: .algorithm)
    let value = try container.decode(String.self, forKey: .hexadecimalValue)
    try self.init(algorithm: algorithm, hexadecimalValue: value)
  }

  private enum CodingKeys: String, CodingKey {
    case algorithm
    case hexadecimalValue
  }
}
