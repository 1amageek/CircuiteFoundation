/// A producer-defined semantic role for an artifact.
///
/// Roles remain open tokens because domain engines may introduce new roles
/// without requiring a Foundation release.
public struct ArtifactRole: Sendable, Hashable, RawRepresentable {
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

  public static let input = Self(uncheckedRawValue: "input")
  public static let output = Self(uncheckedRawValue: "output")
  public static let primary = Self(uncheckedRawValue: "primary")

  private init(uncheckedRawValue value: String) {
    rawValue = value
  }
}
