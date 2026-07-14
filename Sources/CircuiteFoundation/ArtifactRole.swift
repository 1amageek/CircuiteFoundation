import Foundation

/// A producer-defined semantic role for an artifact.
///
/// Roles remain open tokens because domain engines may introduce new roles
/// without requiring a Foundation release.
public struct ArtifactRole: Sendable, Hashable, Codable, RawRepresentable {
  public let rawValue: String

  public init?(rawValue: String) {
    do {
      try self.init(validatingRawValue: rawValue)
    } catch {
      return nil
    }
  }

  public init(validatingRawValue rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Artifact role")
    guard !rawValue.contains("/"), !rawValue.contains("\\") else {
      throw ArtifactRoleError.containsPathSeparator(rawValue)
    }
    self.rawValue = rawValue
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(validatingRawValue: container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public static let input = Self(uncheckedRawValue: "input")
  public static let output = Self(uncheckedRawValue: "output")
  public static let primary = Self(uncheckedRawValue: "primary")

  private init(uncheckedRawValue value: String) {
    rawValue = value
  }
}
