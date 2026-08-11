public struct ExternalObjectReference: Sendable, Hashable {
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

}
