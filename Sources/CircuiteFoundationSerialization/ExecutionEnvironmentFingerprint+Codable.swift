import CircuiteFoundation

extension ExecutionEnvironmentFingerprint: Codable {
  private enum CodingKeys: String, CodingKey {
    case platform
    case architecture
    case toolchain
    case environmentDigest
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      platform: container.decode(String.self, forKey: .platform),
      architecture: container.decode(String.self, forKey: .architecture),
      toolchain: container.decode(String.self, forKey: .toolchain),
      environmentDigest: container.decodeIfPresent(
        ContentDigest.self,
        forKey: .environmentDigest
      )
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(platform, forKey: .platform)
    try container.encode(architecture, forKey: .architecture)
    try container.encode(toolchain, forKey: .toolchain)
    try container.encodeIfPresent(environmentDigest, forKey: .environmentDigest)
  }
}
