public struct SchemaVersion: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
  public let major: UInt16
  public let minor: UInt16
  public let patch: UInt16

  public static let v1 = Self(major: 1, minor: 0, patch: 0)
  public static let v2 = Self(major: 2, minor: 0, patch: 0)

  public var description: String {
    "\(major).\(minor).\(patch)"
  }

  public init(major: UInt16, minor: UInt16, patch: UInt16) {
    self.major = major
    self.minor = minor
    self.patch = patch
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
  }
}
