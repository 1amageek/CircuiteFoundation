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
}
