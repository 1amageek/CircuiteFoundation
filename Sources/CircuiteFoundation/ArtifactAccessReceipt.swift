public struct ArtifactAccessReceipt: Sendable, Hashable {
  public let observedArtifactID: ArtifactID
  public let totalByteCount: UInt64
  public let cumulativeWork: ArtifactAccessWorkReport

  public init(
    observedArtifactID: ArtifactID,
    totalByteCount: UInt64,
    cumulativeWork: ArtifactAccessWorkReport
  ) {
    self.observedArtifactID = observedArtifactID
    self.totalByteCount = totalByteCount
    self.cumulativeWork = cumulativeWork
  }
}
