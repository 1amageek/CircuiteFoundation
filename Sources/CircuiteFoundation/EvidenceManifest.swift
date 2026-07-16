import Foundation

public struct EvidenceManifest: Sendable, Hashable, Codable, Identifiable {
  public static let currentSchemaVersion = SchemaVersion.v2

  public let id: UUID
  public let schemaVersion: SchemaVersion
  public let provenance: ExecutionProvenance
  public let artifacts: [ArtifactReference]

  public init(
    id: UUID = UUID(),
    schemaVersion: SchemaVersion = Self.currentSchemaVersion,
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
    self.id = try container.decode(UUID.self, forKey: .id)
    self.schemaVersion = try container.decode(SchemaVersion.self, forKey: .schemaVersion)
    guard schemaVersion == Self.currentSchemaVersion else {
      throw DecodingError.dataCorruptedError(
        forKey: .schemaVersion,
        in: container,
        debugDescription: "Expected evidence manifest schema version \(Self.currentSchemaVersion)."
      )
    }
    self.provenance = try container.decode(ExecutionProvenance.self, forKey: .provenance)
    self.artifacts = try container.decode([ArtifactReference].self, forKey: .artifacts)
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case schemaVersion
    case provenance
    case artifacts
  }
}
