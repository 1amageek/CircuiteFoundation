public struct ContentDigestResult: Sendable, Hashable {
  public let digest: ContentDigest
  public let totalByteCount: UInt64
  public let updateCount: UInt64

  public init(
    digest: ContentDigest,
    totalByteCount: UInt64,
    updateCount: UInt64
  ) {
    self.digest = digest
    self.totalByteCount = totalByteCount
    self.updateCount = updateCount
  }
}
