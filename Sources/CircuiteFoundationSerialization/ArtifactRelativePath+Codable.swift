import CircuiteFoundation

extension ArtifactRelativePath: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(segments: container.decode([String].self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(segments)
  }
}
