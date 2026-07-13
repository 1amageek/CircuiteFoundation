public struct ArtifactIntegrity: Sendable, Hashable, Codable {
  public let issues: [ArtifactIntegrityIssue]

  public var isVerified: Bool { issues.isEmpty }

  public init(issues: [ArtifactIntegrityIssue] = []) {
    self.issues = issues
  }
}
