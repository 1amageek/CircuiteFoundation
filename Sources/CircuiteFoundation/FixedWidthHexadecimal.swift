enum FixedWidthHexadecimal {
  static func encode(high: UInt64, low: UInt64) -> String {
    encode(high) + encode(low)
  }

  static func encode(_ value: UInt64) -> String {
    let digits = Array("0123456789abcdef".utf8)
    var bytes = Array(repeating: UInt8(48), count: 16)
    var remaining = value
    for index in stride(from: 15, through: 0, by: -1) {
      bytes[index] = digits[Int(remaining & 0x0f)]
      remaining >>= 4
    }
    return String(decoding: bytes, as: UTF8.self)
  }

  static func decode128(_ value: String, kind: String) throws -> (UInt64, UInt64) {
    let bytes = Array(value.utf8)
    guard bytes.count == 32, bytes.allSatisfy(isLowercaseHexadecimal) else {
      throw DesignIdentityError.invalidCanonicalEncoding(kind: kind, value: value)
    }
    return (
      try decode(bytes[0..<16], original: value, kind: kind),
      try decode(bytes[16..<32], original: value, kind: kind)
    )
  }

  static func decode64(_ value: String, kind: String) throws -> UInt64 {
    let bytes = Array(value.utf8)
    guard bytes.count == 16, bytes.allSatisfy(isLowercaseHexadecimal) else {
      throw DesignIdentityError.invalidCanonicalEncoding(kind: kind, value: value)
    }
    return try decode(bytes[...], original: value, kind: kind)
  }

  private static func decode(
    _ bytes: ArraySlice<UInt8>,
    original: String,
    kind: String
  ) throws -> UInt64 {
    var result: UInt64 = 0
    for byte in bytes {
      result <<= 4
      switch byte {
      case 48...57: result |= UInt64(byte - 48)
      case 97...102: result |= UInt64(byte - 87)
      default:
        throw DesignIdentityError.invalidCanonicalEncoding(kind: kind, value: original)
      }
    }
    return result
  }

  private static func isLowercaseHexadecimal(_ byte: UInt8) -> Bool {
    (byte >= 48 && byte <= 57) || (byte >= 97 && byte <= 102)
  }
}
