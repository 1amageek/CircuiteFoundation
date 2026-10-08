import CircuiteFoundation

public protocol ArtifactSourceDiscovering: Sendable {
  func discover(_ intent: ArtifactSourceDiscoveryIntent)
    async throws(ArtifactSourceDiscoveryError) -> ArtifactDiscoveredSource
  func enumerate(_ intent: ArtifactDirectoryInventoryIntent)
    async throws(ArtifactSourceDiscoveryError) -> ArtifactDirectoryInventory
}
