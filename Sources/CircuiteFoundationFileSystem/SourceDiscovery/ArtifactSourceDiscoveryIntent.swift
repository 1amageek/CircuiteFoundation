import CircuiteFoundation

public struct ArtifactSourceDiscoveryIntent: Sendable {
  public let rootID: ArtifactRootID
  public let relativePath: ArtifactRelativePath
  public let descriptor: ArtifactDescriptor
  public let budget: ArtifactAccessBudget

  public init(rootID: ArtifactRootID, relativePath: ArtifactRelativePath,
              descriptor: ArtifactDescriptor, budget: ArtifactAccessBudget) {
    self.rootID = rootID
    self.relativePath = relativePath
    self.descriptor = descriptor
    self.budget = budget
  }
}
