public struct EvidenceManifest: Sendable, Hashable, Identifiable {
  public static let currentSchemaVersion = SchemaVersion.v3

  public let id: EvidenceManifestID
  public let schemaVersion: SchemaVersion
  public let provenance: ExecutionProvenance
  public let artifacts: [ArtifactReference]

  public init(
    id: EvidenceManifestID,
    schemaVersion: SchemaVersion = Self.currentSchemaVersion,
    provenance: ExecutionProvenance,
    artifacts: [ArtifactReference]
  ) {
    self.id = id
    self.schemaVersion = schemaVersion
    self.provenance = provenance
    self.artifacts = artifacts
  }

  public static func contentAddressed(
    schemaVersion: SchemaVersion = Self.currentSchemaVersion,
    provenance: ExecutionProvenance,
    artifacts: [ArtifactReference],
    digester: any ContentDigesting
  ) throws(ContentDigestError) -> Self {
    let canonicalBytes = EvidenceManifestCanonicalEncoding.encode(
      schemaVersion: schemaVersion,
      provenance: provenance,
      artifacts: artifacts
    )
    let byteCount = UInt64(canonicalBytes.count)
    let limits = try ContentDigestSessionLimits(
      maximumChunkByteCount: max(byteCount, 1),
      maximumTotalByteCount: max(byteCount, 1),
      maximumUpdateCount: 1
    )
    let result = try digester.digest(using: .sha256, limits: limits) {
      (lease: borrowing ContentDigestUpdateLease) throws(ContentDigestError) in
      try lease.update(canonicalBytes)
    }
    let digestBytes = EvidenceManifestCanonicalEncoding.decodeDigest(result.digest)
    guard digestBytes.count >= 16 else {
      throw .finalizationFailed(reason: "Evidence manifest digest contains fewer than 16 bytes.")
    }
    let high = EvidenceManifestCanonicalEncoding.decodeUInt64(digestBytes[0..<8])
    let low = EvidenceManifestCanonicalEncoding.decodeUInt64(digestBytes[8..<16])
    return Self(
      id: EvidenceManifestID(high: high, low: low),
      schemaVersion: schemaVersion,
      provenance: provenance,
      artifacts: artifacts
    )
  }

}

private enum EvidenceManifestCanonicalEncoding {
  static func encode(
    schemaVersion: SchemaVersion,
    provenance: ExecutionProvenance,
    artifacts: [ArtifactReference]
  ) -> [UInt8] {
    var writer = CanonicalByteWriter()
    writer.append("CircuiteEvidenceManifest")
    writer.append(schemaVersion.description)
    writer.append(provenance.producer)
    writer.append(provenance.supportingTools)
    writer.append(provenance.inputs)
    writer.append(provenance.invocation)
    writer.append(provenance.environment)
    writer.append(provenance.configurationDigest)
    writer.append(provenance.inputDesignRevision)
    writer.append(provenance.outputDesignRevision)
    writer.append(provenance.randomSeed)
    writer.append(provenance.startedAt)
    writer.append(provenance.completedAt)
    writer.append(artifacts)
    return writer.bytes
  }

  static func decodeDigest(_ digest: ContentDigest) -> [UInt8] {
    let bytes = Array(digest.hexadecimalValue.utf8)
    var result: [UInt8] = []
    result.reserveCapacity(bytes.count / 2)
    var index = 0
    while index < bytes.count {
      result.append((nibble(bytes[index]) << 4) | nibble(bytes[index + 1]))
      index += 2
    }
    return result
  }

  static func decodeUInt64(_ bytes: ArraySlice<UInt8>) -> UInt64 {
    bytes.reduce(0) { ($0 << 8) | UInt64($1) }
  }

  private static func nibble(_ byte: UInt8) -> UInt8 {
    byte <= 57 ? byte - 48 : byte - 87
  }

  private struct CanonicalByteWriter {
    var bytes: [UInt8] = []

    mutating func append(_ value: String) {
      let encoded = Array(value.utf8)
      append(UInt64(encoded.count))
      bytes.append(contentsOf: encoded)
    }

    mutating func append(_ value: String?) {
      guard let value else { return appendPresence(false) }
      appendPresence(true)
      append(value)
    }

    mutating func append(_ value: UInt64) {
      var value = value.bigEndian
      withUnsafeBytes(of: &value) { bytes.append(contentsOf: $0) }
    }

    mutating func append(_ value: UInt64?) {
      guard let value else { return appendPresence(false) }
      appendPresence(true)
      append(value)
    }

    mutating func append(_ value: ExecutionTimestamp) {
      append(value.secondsSinceUnixEpoch.bitPattern)
    }

    mutating func append(_ value: ProducerIdentity) {
      append(value.kind.rawValue)
      append(value.identifier)
      append(value.version)
      append(value.build)
    }

    mutating func append(_ values: [ProducerIdentity]) {
      append(UInt64(values.count))
      for value in values { append(value) }
    }

    mutating func append(_ value: ContentDigest?) {
      guard let value else { return appendPresence(false) }
      appendPresence(true)
      append(value.algorithm.rawValue)
      append(value.hexadecimalValue)
    }

    mutating func append(_ value: DesignRevisionReference?) {
      guard let value else { return appendPresence(false) }
      appendPresence(true)
      append(value.databaseID.description)
      append(value.revisionID.description)
    }

    mutating func append(_ value: ExecutionInvocation?) {
      guard let value else { return appendPresence(false) }
      appendPresence(true)
      append(value.mode.rawValue)
      append(value.entryPoint)
      append(value.executable)
      append(UInt64(value.arguments.count))
      for argument in value.arguments { append(argument) }
      append(value.workingDirectory)
    }

    mutating func append(_ value: ExecutionEnvironmentFingerprint?) {
      guard let value else { return appendPresence(false) }
      appendPresence(true)
      append(value.platform)
      append(value.architecture)
      append(value.toolchain)
      append(value.environmentDigest)
    }

    mutating func append(_ values: [ArtifactReference]) {
      append(UInt64(values.count))
      for value in values {
        bytes.append(contentsOf: value.id.canonicalBytes)
        append(value.descriptor.role.rawValue)
        append(value.descriptor.kind.rawValue)
        append(value.descriptor.format.rawValue)
      }
    }

    private mutating func appendPresence(_ isPresent: Bool) {
      bytes.append(isPresent ? 1 : 0)
    }
  }
}
