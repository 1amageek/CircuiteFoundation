public struct ArtifactReference: Sendable, Hashable, Codable, Identifiable {
  public let id: ArtifactID
  public let locator: ArtifactLocator
  public let digest: ContentDigest
  public let byteCount: UInt64
  public let producer: ProducerIdentity?

  public init(
    id: ArtifactID = ArtifactID(),
    locator: ArtifactLocator,
    digest: ContentDigest,
    byteCount: UInt64,
    producer: ProducerIdentity? = nil
  ) {
    self.id = id
    self.locator = locator
    self.digest = digest
    self.byteCount = byteCount
    self.producer = producer
  }
}
