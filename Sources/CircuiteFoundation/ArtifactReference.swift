public struct ArtifactReference: Sendable, Hashable, Identifiable {
  public let id: ArtifactID
  public let descriptor: ArtifactDescriptor

  public var digest: ContentDigest { id.digest }
  public var byteCount: UInt64 { id.byteCount }

  public init(
    id: ArtifactID,
    descriptor: ArtifactDescriptor
  ) {
    self.id = id
    self.descriptor = descriptor
  }

  public init(
    digest: ContentDigest,
    byteCount: UInt64,
    descriptor: ArtifactDescriptor
  ) throws(ArtifactIDError) {
    self.init(
      id: try ArtifactID(digest: digest, byteCount: byteCount),
      descriptor: descriptor
    )
  }
}
