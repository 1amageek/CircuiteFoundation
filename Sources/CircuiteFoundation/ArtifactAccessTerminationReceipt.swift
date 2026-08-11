public struct ArtifactAccessTerminationReceipt: Sendable, Hashable {
  public let sessionIdentity: ArtifactAccessSessionIdentity
  public let didReachTerminalPage: Bool

  public init(
    sessionIdentity: ArtifactAccessSessionIdentity,
    didReachTerminalPage: Bool
  ) {
    self.sessionIdentity = sessionIdentity
    self.didReachTerminalPage = didReachTerminalPage
  }
}
