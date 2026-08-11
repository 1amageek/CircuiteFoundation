import CircuiteFoundation

extension SuggestedAction: Codable {
  private enum CodingKeys: String, CodingKey {
    case code
    case summary
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      code: try container.decode(String.self, forKey: .code),
      summary: try container.decode(String.self, forKey: .summary)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(code, forKey: .code)
    try container.encode(summary, forKey: .summary)
  }
}
