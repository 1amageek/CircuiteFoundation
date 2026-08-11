public struct ContentDigest: Sendable, Hashable {
  public let algorithm: ContentDigestAlgorithm
  public let hexadecimalValue: String

  public init(
    algorithm: ContentDigestAlgorithm,
    hexadecimalValue: String
  ) throws(ContentDigestError) {
    let normalizedValue = hexadecimalValue.lowercased()
    guard !normalizedValue.isEmpty else {
      throw ContentDigestError.emptyHexadecimalValue
    }
    guard normalizedValue.utf8.allSatisfy(Self.isASCIIHexDigit) else {
      throw ContentDigestError.invalidHexadecimalValue(hexadecimalValue)
    }
    guard normalizedValue.utf8.count.isMultiple(of: 2) else {
      throw ContentDigestError.incompleteByte(hexadecimalValue)
    }
    if algorithm == .sha256, normalizedValue.utf8.count != 64 {
      throw ContentDigestError.invalidLength(
        algorithm: algorithm,
        actual: normalizedValue.utf8.count,
        expected: 64
      )
    }
    self.algorithm = algorithm
    self.hexadecimalValue = normalizedValue
  }

  private static func isASCIIHexDigit(_ byte: UInt8) -> Bool {
    (byte >= 48 && byte <= 57)
      || (byte >= 65 && byte <= 70)
      || (byte >= 97 && byte <= 102)
  }

}
