import Foundation

public struct EvidenceManifest: Sendable, Hashable, Codable, Identifiable {
  public let id: UUID
  public let schemaVersion: SchemaVersion
  public let provenance: ExecutionProvenance
  public let artifacts: [ArtifactReference]

  public init(
    id: UUID = UUID(),
    schemaVersion: SchemaVersion = .v1,
    provenance: ExecutionProvenance,
    artifacts: [ArtifactReference]
  ) {
    self.id = id
    self.schemaVersion = schemaVersion
    self.provenance = provenance
    self.artifacts = artifacts
  }
}
