import Foundation

public struct ArtifactLocator: Sendable, Hashable, Codable {
  public let location: ArtifactLocation
  public let role: ArtifactRole
  public let kind: ArtifactKind
  public let format: ArtifactFormat

  @available(*, deprecated, message: "Provide an ArtifactRole during migration.")
  public init(
    location: ArtifactLocation,
    kind: ArtifactKind,
    format: ArtifactFormat
  ) {
    self.location = location
    self.role = .legacyUnspecified
    self.kind = kind
    self.format = format
  }

  public init(
    location: ArtifactLocation,
    role: ArtifactRole,
    kind: ArtifactKind,
    format: ArtifactFormat
  ) {
    self.location = location
    self.role = role
    self.kind = kind
    self.format = format
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.location = try container.decode(ArtifactLocation.self, forKey: .location)
    self.role = try container.decodeIfPresent(ArtifactRole.self, forKey: .role) ?? .legacyUnspecified
    self.kind = try container.decode(ArtifactKind.self, forKey: .kind)
    self.format = try container.decode(ArtifactFormat.self, forKey: .format)
  }

  private enum CodingKeys: String, CodingKey {
    case location
    case role
    case kind
    case format
  }
}
