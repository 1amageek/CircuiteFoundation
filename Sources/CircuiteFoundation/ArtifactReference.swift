import Foundation

public struct ArtifactReference: Sendable, Hashable, Codable, Identifiable {
  public let id: ArtifactID
  public let locator: ArtifactLocator
  public let digest: ContentDigest
  public let byteCount: UInt64
  public let producer: ProducerIdentity?

  public init(
    id: ArtifactID? = nil,
    locator: ArtifactLocator,
    digest: ContentDigest,
    byteCount: UInt64,
    producer: ProducerIdentity? = nil
  ) {
    let producerKey = producer.map {
      [$0.kind.rawValue, $0.identifier, $0.version, $0.build ?? ""].joined(separator: "\u{001F}")
    } ?? ""
    let stableKey = [
      locator.location.storage.rawValue,
      locator.location.value,
      locator.role.rawValue,
      locator.kind.rawValue,
      locator.format.rawValue,
      digest.algorithm.rawValue,
      digest.hexadecimalValue,
      String(byteCount),
      producerKey,
    ].joined(separator: "\u{001E}")
    self.id = id ?? ArtifactID(stableKey: stableKey)
    self.locator = locator
    self.digest = digest
    self.byteCount = byteCount
    self.producer = producer
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.locator) {
      self.init(
        id: try container.decodeIfPresent(ArtifactID.self, forKey: .id),
        locator: try container.decode(ArtifactLocator.self, forKey: .locator),
        digest: try container.decode(ContentDigest.self, forKey: .digest),
        byteCount: try container.decode(UInt64.self, forKey: .byteCount),
        producer: try container.decodeIfPresent(ProducerIdentity.self, forKey: .producer)
      )
      return
    }

    // Decode the pre-v2 artifact shape once so existing fixtures and
    // workspaces can be migrated without a compatibility package.
    let path = try container.decode(String.self, forKey: .path)
    let kind = try ArtifactKind(legacyRawValue: container.decode(String.self, forKey: .kind))
    let format = try ArtifactFormat(legacyRawValue: container.decode(String.self, forKey: .format))
    let location: ArtifactLocation
    if path.hasPrefix("/") {
      location = try ArtifactLocation(fileURL: URL(filePath: path))
    } else {
      location = try ArtifactLocation(workspaceRelativePath: path)
    }
    let locator = ArtifactLocator(
      location: location,
      role: .legacyUnspecified,
      kind: kind,
      format: format
    )
    let digestValue = try container.decode(String.self, forKey: .sha256)
    let digest = try ContentDigest(algorithm: .sha256, hexadecimalValue: digestValue)
    // Pre-v2 fixtures did not always persist a byte count. Keep those
    // artifacts readable during the one-time migration; verification will
    // still reject a zero count when the artifact is required to be intact.
    let byteCount = try container.decodeIfPresent(UInt64.self, forKey: .byteCount) ?? 0
    let artifactID = try container.decodeIfPresent(String.self, forKey: .artifactID).map {
      try ArtifactID(rawValue: $0)
    }
    self.init(
      id: artifactID,
      locator: locator,
      digest: digest,
      byteCount: byteCount
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(locator, forKey: .locator)
    try container.encode(digest, forKey: .digest)
    try container.encode(byteCount, forKey: .byteCount)
    try container.encodeIfPresent(producer, forKey: .producer)
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case locator
    case digest
    case byteCount
    case producer
    case artifactID
    case path
    case kind
    case format
    case sha256
  }
}
