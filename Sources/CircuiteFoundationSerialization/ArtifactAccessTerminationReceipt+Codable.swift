import CircuiteFoundation

extension ArtifactAccessTerminationReceipt: Codable {
  private enum CodingKeys: String, CodingKey {
    case sessionIdentity
    case didReachTerminalPage
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      sessionIdentity: try container.decode(
        ArtifactAccessSessionIdentity.self,
        forKey: .sessionIdentity
      ),
      didReachTerminalPage: try container.decode(
        Bool.self,
        forKey: .didReachTerminalPage
      )
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(sessionIdentity, forKey: .sessionIdentity)
    try container.encode(didReachTerminalPage, forKey: .didReachTerminalPage)
  }
}
