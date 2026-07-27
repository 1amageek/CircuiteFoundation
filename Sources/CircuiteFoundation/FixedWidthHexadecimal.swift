import Foundation

enum FixedWidthHexadecimal {
  static func encode(high: UInt64, low: UInt64) -> String {
    String(format: "%016llx%016llx", high, low)
  }

  static func encode(_ value: UInt64) -> String {
    String(format: "%016llx", value)
  }

  static func decode128(_ value: String, kind: String) throws -> (UInt64, UInt64) {
    guard value.count == 32, value.utf8.allSatisfy(isLowercaseHexadecimal) else {
      throw DesignIdentityError.invalidCanonicalEncoding(kind: kind, value: value)
    }
    let midpoint = value.index(value.startIndex, offsetBy: 16)
    guard
      let high = UInt64(value[..<midpoint], radix: 16),
      let low = UInt64(value[midpoint...], radix: 16)
    else {
      throw DesignIdentityError.invalidCanonicalEncoding(kind: kind, value: value)
    }
    return (high, low)
  }

  static func decode64(_ value: String, kind: String) throws -> UInt64 {
    guard
      value.count == 16,
      value.utf8.allSatisfy(isLowercaseHexadecimal),
      let decoded = UInt64(value, radix: 16)
    else {
      throw DesignIdentityError.invalidCanonicalEncoding(kind: kind, value: value)
    }
    return decoded
  }

  private static func isLowercaseHexadecimal(_ byte: UInt8) -> Bool {
    (byte >= 48 && byte <= 57) || (byte >= 97 && byte <= 102)
  }
}
