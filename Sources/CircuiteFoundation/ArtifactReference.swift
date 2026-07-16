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
    self.init(
      id: try container.decode(ArtifactID.self, forKey: .id),
      locator: try container.decode(ArtifactLocator.self, forKey: .locator),
      digest: try container.decode(ContentDigest.self, forKey: .digest),
      byteCount: try container.decode(UInt64.self, forKey: .byteCount),
      producer: try container.decodeIfPresent(ProducerIdentity.self, forKey: .producer)
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
  }
}
