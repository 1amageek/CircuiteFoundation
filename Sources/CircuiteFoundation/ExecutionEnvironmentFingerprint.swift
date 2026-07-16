import Foundation

/// A normalized description of the environment relevant to reproducibility.
/// Raw environment variables are intentionally excluded; callers should store
/// a digest of a sanitized environment manifest instead.
public struct ExecutionEnvironmentFingerprint: Sendable, Hashable, Codable {
  public let platform: String
  public let architecture: String
  public let toolchain: String
  public let environmentDigest: ContentDigest?

  public init(
    platform: String,
    architecture: String,
    toolchain: String,
    environmentDigest: ContentDigest? = nil
  ) throws {
    try TokenValidation.validate(platform, kind: "Execution platform")
    try TokenValidation.validate(architecture, kind: "Execution architecture")
    try TokenValidation.validate(toolchain, kind: "Execution toolchain")
    self.platform = platform
    self.architecture = architecture
    self.toolchain = toolchain
    self.environmentDigest = environmentDigest
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

  private enum CodingKeys: String, CodingKey {
    case platform
    case architecture
    case toolchain
    case environmentDigest
  }
}
