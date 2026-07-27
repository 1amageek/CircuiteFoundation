import Foundation

public struct ExternalObjectReference: Sendable, Hashable, Codable {
  public let systemID: ExternalSystemID
  public let sourceScopeDigest: ContentDigest
  public let objectKind: String
  public let opaqueIdentifier: String

  public init(
    systemID: ExternalSystemID,
    sourceScopeDigest: ContentDigest,
    objectKind: String,
    opaqueIdentifier: String
  ) throws {
    try TokenValidation.validate(objectKind, kind: "External object kind")
    try TokenValidation.validate(opaqueIdentifier, kind: "External opaque identifier")
    self.systemID = systemID
    self.sourceScopeDigest = sourceScopeDigest
    self.objectKind = objectKind
    self.opaqueIdentifier = opaqueIdentifier
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      systemID: container.decode(ExternalSystemID.self, forKey: .systemID),
      sourceScopeDigest: container.decode(ContentDigest.self, forKey: .sourceScopeDigest),
      objectKind: container.decode(String.self, forKey: .objectKind),
      opaqueIdentifier: container.decode(String.self, forKey: .opaqueIdentifier)
    )
  }

  private enum CodingKeys: String, CodingKey {
    case systemID
    case sourceScopeDigest
    case objectKind
    case opaqueIdentifier
  }
}
