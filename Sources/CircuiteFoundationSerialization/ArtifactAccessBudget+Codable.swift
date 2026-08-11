import CircuiteFoundation

extension ArtifactAccessBudget: Codable {
  private enum CodingKeys: String, CodingKey {
    case maximumPageByteCount
    case maximumTotalByteCount
    case maximumPageCount
    case maximumWorkUnitCount
    case maximumDurationNanoseconds
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      maximumPageByteCount: container.decode(
        UInt64.self,
        forKey: .maximumPageByteCount
      ),
      maximumTotalByteCount: container.decode(
        UInt64.self,
        forKey: .maximumTotalByteCount
      ),
      maximumPageCount: container.decode(UInt64.self, forKey: .maximumPageCount),
      maximumWorkUnitCount: container.decode(
        UInt64.self,
        forKey: .maximumWorkUnitCount
      ),
      maximumDurationNanoseconds: container.decode(
        UInt64.self,
        forKey: .maximumDurationNanoseconds
      )
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(maximumPageByteCount, forKey: .maximumPageByteCount)
    try container.encode(maximumTotalByteCount, forKey: .maximumTotalByteCount)
    try container.encode(maximumPageCount, forKey: .maximumPageCount)
    try container.encode(maximumWorkUnitCount, forKey: .maximumWorkUnitCount)
    try container.encode(
      maximumDurationNanoseconds,
      forKey: .maximumDurationNanoseconds
    )
  }
}
