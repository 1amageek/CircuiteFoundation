public struct ArtifactID:
  Sendable,
  Hashable,
  Identifiable,
  CustomStringConvertible
{
  public let digest: ContentDigest
  public let byteCount: UInt64

  public var id: Self { self }

  public var description: String {
    Self.hexadecimalEncode(canonicalBytes)
  }

  public init(
    digest: ContentDigest,
    byteCount: UInt64
  ) throws(ArtifactIDError) {
    let algorithmByteCount = digest.algorithm.rawValue.utf8.count
    guard algorithmByteCount <= Int(UInt16.max) else {
      throw .algorithmTokenTooLong(actual: algorithmByteCount)
    }
    let digestByteCount = digest.hexadecimalValue.utf8.count / 2
    guard digestByteCount <= Int(UInt16.max) else {
      throw .digestTooLong(actual: digestByteCount)
    }
    self.digest = digest
    self.byteCount = byteCount
  }

  public init(canonicalHexadecimalValue value: String) throws(ArtifactIDError) {
    let bytes = try Self.hexadecimalDecode(value)
    var cursor = ArtifactIDByteCursor(bytes: bytes)
    let domain = Array("CircuiteArtifactContent".utf8)
    guard try cursor.read(count: domain.count) == domain,
          try cursor.readByte() == 0 else {
      throw .invalidDomain
    }
    guard try cursor.readUInt16() == 1 else {
      throw .unsupportedVersion
    }
    let algorithmBytes = try cursor.readLengthPrefixedBytes()
    let algorithmValue = String(decoding: algorithmBytes, as: UTF8.self)
    guard Array(algorithmValue.utf8) == algorithmBytes else {
      throw .invalidAlgorithmEncoding
    }
    let digestBytes = try cursor.readLengthPrefixedBytes()
    let byteCount = try cursor.readUInt64()
    guard cursor.isAtEnd else {
      throw .trailingBytes
    }

    let algorithm: ContentDigestAlgorithm
    do {
      algorithm = try ContentDigestAlgorithm(rawValue: algorithmValue)
    } catch {
      throw .invalidDigestAlgorithm(error)
    }
    let digest: ContentDigest
    do {
      digest = try ContentDigest(
        algorithm: algorithm,
        hexadecimalValue: Self.hexadecimalEncode(digestBytes)
      )
    } catch {
      throw .invalidDigest(error)
    }
    try self.init(digest: digest, byteCount: byteCount)
  }

  public var canonicalBytes: [UInt8] {
    var bytes = Array("CircuiteArtifactContent".utf8)
    bytes.append(0)
    bytes.append(contentsOf: Self.bigEndianBytes(UInt16(1)))

    let algorithmBytes = Array(digest.algorithm.rawValue.utf8)
    bytes.append(contentsOf: Self.bigEndianBytes(UInt16(algorithmBytes.count)))
    bytes.append(contentsOf: algorithmBytes)

    let digestBytes = Self.uncheckedHexadecimalDecode(digest.hexadecimalValue)
    bytes.append(contentsOf: Self.bigEndianBytes(UInt16(digestBytes.count)))
    bytes.append(contentsOf: digestBytes)
    bytes.append(contentsOf: Self.bigEndianBytes(byteCount))
    return bytes
  }

  private static func hexadecimalEncode(_ bytes: [UInt8]) -> String {
    let digits = Array("0123456789abcdef".utf8)
    var encoded: [UInt8] = []
    encoded.reserveCapacity(bytes.count * 2)
    for byte in bytes {
      encoded.append(digits[Int(byte >> 4)])
      encoded.append(digits[Int(byte & 0x0f)])
    }
    return String(decoding: encoded, as: UTF8.self)
  }

  private static func hexadecimalDecode(_ value: String) throws(ArtifactIDError) -> [UInt8] {
    let encoded = Array(value.utf8)
    guard !encoded.isEmpty, encoded.count.isMultiple(of: 2) else {
      throw .invalidCanonicalEncoding
    }
    var decoded: [UInt8] = []
    decoded.reserveCapacity(encoded.count / 2)
    var index = 0
    while index < encoded.count {
      guard let high = hexadecimalNibble(encoded[index]),
            let low = hexadecimalNibble(encoded[index + 1]) else {
        throw .invalidCanonicalEncoding
      }
      decoded.append((high << 4) | low)
      index += 2
    }
    return decoded
  }

  private static func uncheckedHexadecimalDecode(_ value: String) -> [UInt8] {
    let encoded = Array(value.utf8)
    var decoded: [UInt8] = []
    decoded.reserveCapacity(encoded.count / 2)
    var index = 0
    while index < encoded.count {
      let high = hexadecimalNibble(encoded[index])!
      let low = hexadecimalNibble(encoded[index + 1])!
      decoded.append((high << 4) | low)
      index += 2
    }
    return decoded
  }

  private static func hexadecimalNibble(_ byte: UInt8) -> UInt8? {
    switch byte {
    case 48...57: byte - 48
    case 97...102: byte - 87
    default: nil
    }
  }

  private static func bigEndianBytes<T: FixedWidthInteger>(_ value: T) -> [UInt8] {
    var value = value.bigEndian
    return withUnsafeBytes(of: &value) { Array($0) }
  }
}

private struct ArtifactIDByteCursor {
  let bytes: [UInt8]
  var offset = 0

  var isAtEnd: Bool { offset == bytes.count }

  mutating func readByte() throws(ArtifactIDError) -> UInt8 {
    guard offset < bytes.count else { throw .truncatedEncoding }
    defer { offset += 1 }
    return bytes[offset]
  }

  mutating func read(count: Int) throws(ArtifactIDError) -> [UInt8] {
    guard count >= 0, offset <= bytes.count, count <= bytes.count - offset else {
      throw .truncatedEncoding
    }
    let result = Array(bytes[offset..<(offset + count)])
    offset += count
    return result
  }

  mutating func readUInt16() throws(ArtifactIDError) -> UInt16 {
    let value = try read(count: 2)
    return (UInt16(value[0]) << 8) | UInt16(value[1])
  }

  mutating func readUInt64() throws(ArtifactIDError) -> UInt64 {
    let value = try read(count: 8)
    var result: UInt64 = 0
    for byte in value {
      result = (result << 8) | UInt64(byte)
    }
    return result
  }

  mutating func readLengthPrefixedBytes() throws(ArtifactIDError) -> [UInt8] {
    try read(count: Int(readUInt16()))
  }
}
