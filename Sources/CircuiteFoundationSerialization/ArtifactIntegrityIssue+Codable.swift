import CircuiteFoundation

extension ArtifactIntegrityIssue.Code: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    guard let value = Self(rawValue: rawValue) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unknown artifact integrity issue code."
      )
    }
    self = value
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

extension ArtifactIntegrityIssue: Codable {
  private enum CodingKeys: String, CodingKey {
    case code
    case location
    case detail
    case expectedByteCount
    case actualByteCount
    case expectedDigest
    case actualDigest
    case digestAlgorithm
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let code = try container.decode(Code.self, forKey: .code)
    do {
      try self.init(
        validatingCode: code,
        location: container.decodeIfPresent(String.self, forKey: .location),
        detail: container.decodeIfPresent(String.self, forKey: .detail),
        expectedByteCount: container.decodeIfPresent(UInt64.self, forKey: .expectedByteCount),
        actualByteCount: container.decodeIfPresent(UInt64.self, forKey: .actualByteCount),
        expectedDigest: container.decodeIfPresent(ContentDigest.self, forKey: .expectedDigest),
        actualDigest: container.decodeIfPresent(ContentDigest.self, forKey: .actualDigest),
        digestAlgorithm: container.decodeIfPresent(
          ContentDigestAlgorithm.self,
          forKey: .digestAlgorithm
        )
      )
    } catch {
      throw DecodingError.dataCorruptedError(
        forKey: .code,
        in: container,
        debugDescription: "Artifact integrity issue payload does not match its code."
      )
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(code, forKey: .code)
    try container.encodeIfPresent(location, forKey: .location)
    try container.encodeIfPresent(detail, forKey: .detail)
    try container.encodeIfPresent(expectedByteCount, forKey: .expectedByteCount)
    try container.encodeIfPresent(actualByteCount, forKey: .actualByteCount)
    try container.encodeIfPresent(expectedDigest, forKey: .expectedDigest)
    try container.encodeIfPresent(actualDigest, forKey: .actualDigest)
    try container.encodeIfPresent(digestAlgorithm, forKey: .digestAlgorithm)
  }
}
