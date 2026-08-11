import CircuiteFoundation

extension ArtifactIntegrity: Codable {
  private enum CodingKeys: String, CodingKey {
    case issues
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(issues: try container.decode([ArtifactIntegrityIssue].self, forKey: .issues))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(issues, forKey: .issues)
  }
}
