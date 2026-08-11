import CircuiteFoundation

extension EvidenceManifest: Codable {
  private enum CodingKeys: String, CodingKey {
    case id
    case schemaVersion
    case provenance
    case artifacts
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let schemaVersion = try container.decode(SchemaVersion.self, forKey: .schemaVersion)
    guard schemaVersion == Self.currentSchemaVersion else {
      throw DecodingError.dataCorruptedError(
        forKey: .schemaVersion,
        in: container,
        debugDescription: "Expected evidence manifest schema version \(Self.currentSchemaVersion)."
      )
    }
    self.init(
      id: try container.decode(EvidenceManifestID.self, forKey: .id),
      schemaVersion: schemaVersion,
      provenance: try container.decode(ExecutionProvenance.self, forKey: .provenance),
      artifacts: try container.decode([ArtifactReference].self, forKey: .artifacts)
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(schemaVersion, forKey: .schemaVersion)
    try container.encode(provenance, forKey: .provenance)
    try container.encode(artifacts, forKey: .artifacts)
  }
}
