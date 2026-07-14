import Foundation

public struct EvidenceManifest: Sendable, Hashable, Codable, Identifiable {
  public let id: UUID
  public let schemaVersion: SchemaVersion
  public let provenance: ExecutionProvenance
  public let artifacts: [ArtifactReference]

  public init(
    id: UUID = UUID(),
    schemaVersion: SchemaVersion = .v2,
    provenance: ExecutionProvenance,
    artifacts: [ArtifactReference]
  ) {
    self.id = id
    self.schemaVersion = schemaVersion
    self.provenance = provenance
    self.artifacts = artifacts
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    self.schemaVersion = try container.decode(SchemaVersion.self, forKey: .schemaVersion)
    self.provenance = try container.decode(ExecutionProvenance.self, forKey: .provenance)
    self.artifacts = try container.decodeIfPresent([ArtifactReference].self, forKey: .artifacts) ?? []
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case schemaVersion
    case provenance
    case artifacts
  }
}
