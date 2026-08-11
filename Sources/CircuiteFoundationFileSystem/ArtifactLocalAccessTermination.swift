import CircuiteFoundation

actor ArtifactLocalAccessTermination: ArtifactAccessTermination {
  nonisolated let sessionIdentity: ArtifactAccessSessionIdentity
  private let result: Result<ArtifactAccessTerminationReceipt, ArtifactAccessTerminationError>

  init(
    sessionIdentity: ArtifactAccessSessionIdentity,
    didReachTerminalPage: Bool,
    closeErrorReason: String?
  ) {
    self.sessionIdentity = sessionIdentity
    if let closeErrorReason {
      result = .failure(.cleanupFailed(reason: closeErrorReason))
    } else {
      result = .success(
        ArtifactAccessTerminationReceipt(
          sessionIdentity: sessionIdentity,
          didReachTerminalPage: didReachTerminalPage
        )
      )
    }
  }

  func wait() async throws(ArtifactAccessTerminationError) -> ArtifactAccessTerminationReceipt {
    switch result {
    case .success(let receipt):
      return receipt
    case .failure(let error):
      throw error
    }
  }
}
