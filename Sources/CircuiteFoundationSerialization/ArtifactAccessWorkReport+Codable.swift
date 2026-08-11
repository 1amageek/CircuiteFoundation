import CircuiteFoundation

extension ArtifactAccessWorkReport: Codable {
  private enum CodingKeys: String, CodingKey {
    case pageCount
    case workUnitCount
    case elapsedNanoseconds
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      pageCount: try container.decode(UInt64.self, forKey: .pageCount),
      workUnitCount: try container.decode(UInt64.self, forKey: .workUnitCount),
      elapsedNanoseconds: try container.decode(
        UInt64.self,
        forKey: .elapsedNanoseconds
      )
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(pageCount, forKey: .pageCount)
    try container.encode(workUnitCount, forKey: .workUnitCount)
    try container.encode(elapsedNanoseconds, forKey: .elapsedNanoseconds)
  }
}
