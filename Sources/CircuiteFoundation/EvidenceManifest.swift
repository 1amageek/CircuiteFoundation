import CryptoKit
import Foundation

public struct EvidenceManifest: Sendable, Hashable, Codable, Identifiable {
  public static let currentSchemaVersion = SchemaVersion.v2

  public let id: UUID
  public let schemaVersion: SchemaVersion
  public let provenance: ExecutionProvenance
  public let artifacts: [ArtifactReference]

  public init(
    id: UUID? = nil,
    schemaVersion: SchemaVersion = Self.currentSchemaVersion,
    provenance: ExecutionProvenance,
    artifacts: [ArtifactReference]
  ) {
    self.id = id ?? Self.contentDerivedID(
      schemaVersion: schemaVersion,
      provenance: provenance,
      artifacts: artifacts
    )
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

  private static func contentDerivedID(
    schemaVersion: SchemaVersion,
    provenance: ExecutionProvenance,
    artifacts: [ArtifactReference]
  ) -> UUID {
    var identity = EvidenceIdentityData()
    identity.append(schemaVersion.description)
    identity.append(provenance.producer)
    identity.append(provenance.supportingTools)
    identity.append(provenance.inputs)
    identity.append(provenance.invocation)
    identity.append(provenance.environment)
    identity.append(provenance.configurationDigest)
    identity.append(provenance.designRevision)
    identity.append(provenance.randomSeed)
    identity.append(provenance.startedAt)
    identity.append(provenance.completedAt)
    identity.append(artifacts)

    var bytes = Array(SHA256.hash(data: identity.data).prefix(16))
    bytes[6] = (bytes[6] & 0x0F) | 0x80
    bytes[8] = (bytes[8] & 0x3F) | 0x80
    return UUID(uuid: (
      bytes[0], bytes[1], bytes[2], bytes[3],
      bytes[4], bytes[5], bytes[6], bytes[7],
      bytes[8], bytes[9], bytes[10], bytes[11],
      bytes[12], bytes[13], bytes[14], bytes[15]
    ))
  }
}

private struct EvidenceIdentityData {
  var data = Data()

  mutating func append(_ value: String) {
    appendPresence(true)
    let bytes = Data(value.utf8)
    appendCount(bytes.count)
    data.append(bytes)
  }

  mutating func append(_ value: String?) {
    guard let value else {
      appendPresence(false)
      return
    }
    append(value)
  }

  mutating func append(_ value: UInt64?) {
    guard let value else {
      appendPresence(false)
      return
    }
    appendPresence(true)
    append(value)
  }

  mutating func append(_ value: UInt64) {
    var bigEndianValue = value.bigEndian
    withUnsafeBytes(of: &bigEndianValue) { data.append(contentsOf: $0) }
  }

  mutating func append(_ value: Date) {
    append(value.timeIntervalSinceReferenceDate.bitPattern)
  }

  mutating func append(_ value: ProducerIdentity) {
    append(value.kind.rawValue)
    append(value.identifier)
    append(value.version)
    append(value.build)
  }

  mutating func append(_ values: [ProducerIdentity]) {
    appendCount(values.count)
    for value in values {
      append(value)
    }
  }

  mutating func append(_ value: ContentDigest?) {
    guard let value else {
      appendPresence(false)
      return
    }
    appendPresence(true)
    append(value.algorithm.rawValue)
    append(value.hexadecimalValue)
  }

  mutating func append(_ value: ExecutionInvocation?) {
    guard let value else {
      appendPresence(false)
      return
    }
    appendPresence(true)
    append(value.mode.rawValue)
    append(value.entryPoint)
    append(value.executable)
    appendCount(value.arguments.count)
    for argument in value.arguments {
      append(argument)
    }
    append(value.workingDirectory)
  }

  mutating func append(_ value: ExecutionEnvironmentFingerprint?) {
    guard let value else {
      appendPresence(false)
      return
    }
    appendPresence(true)
    append(value.platform)
    append(value.architecture)
    append(value.toolchain)
    append(value.environmentDigest)
  }

  mutating func append(_ values: [ArtifactReference]) {
    appendCount(values.count)
    for value in values {
      append(value)
    }
  }

  mutating func append(_ value: ArtifactReference) {
    append(value.id.rawValue)
    append(value.locator.location.storage.rawValue)
    append(value.locator.location.value)
    append(value.locator.role.rawValue)
    append(value.locator.kind.rawValue)
    append(value.locator.format.rawValue)
    append(value.digest.algorithm.rawValue)
    append(value.digest.hexadecimalValue)
    append(value.byteCount)
    if let producer = value.producer {
      appendPresence(true)
      append(producer)
    } else {
      appendPresence(false)
    }
  }

  private mutating func appendPresence(_ isPresent: Bool) {
    data.append(isPresent ? 1 : 0)
  }

  private mutating func appendCount(_ count: Int) {
    append(UInt64(count))
  }
}
