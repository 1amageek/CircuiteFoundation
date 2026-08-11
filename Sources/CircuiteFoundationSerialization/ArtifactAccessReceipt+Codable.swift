import CircuiteFoundation

extension ArtifactAccessReceipt: Codable {
  private enum CodingKeys: String, CodingKey {
    case observedArtifactID
    case totalByteCount
    case cumulativeWork
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      observedArtifactID: try container.decode(
        ArtifactID.self,
        forKey: .observedArtifactID
      ),
      totalByteCount: try container.decode(UInt64.self, forKey: .totalByteCount),
      cumulativeWork: try container.decode(
        ArtifactAccessWorkReport.self,
        forKey: .cumulativeWork
      )
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(observedArtifactID, forKey: .observedArtifactID)
    try container.encode(totalByteCount, forKey: .totalByteCount)
    try container.encode(cumulativeWork, forKey: .cumulativeWork)
  }
}
