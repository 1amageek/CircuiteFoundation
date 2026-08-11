public struct ArtifactResourceReference: Sendable, Hashable {
  public let serviceID: ArtifactServiceID
  public let namespaceID: ArtifactResourceNamespaceID
  public let resourceID: ArtifactResourceID
  public let generation: UInt64

  public init(
    serviceID: ArtifactServiceID,
    namespaceID: ArtifactResourceNamespaceID,
    resourceID: ArtifactResourceID,
    generation: UInt64
  ) throws {
    guard generation > 0 else {
      throw ArtifactResourceReferenceError.zeroGeneration
    }
    self.serviceID = serviceID
    self.namespaceID = namespaceID
    self.resourceID = resourceID
    self.generation = generation
  }

}
