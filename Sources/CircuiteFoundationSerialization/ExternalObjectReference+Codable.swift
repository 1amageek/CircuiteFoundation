import CircuiteFoundation

extension ExternalObjectReference: Codable {
  private enum CodingKeys: String, CodingKey {
    case systemID
    case sourceScopeDigest
    case objectKind
    case opaqueIdentifier
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

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(systemID, forKey: .systemID)
    try container.encode(sourceScopeDigest, forKey: .sourceScopeDigest)
    try container.encode(objectKind, forKey: .objectKind)
    try container.encode(opaqueIdentifier, forKey: .opaqueIdentifier)
  }
}
