import Foundation

public struct ArtifactID: Sendable, Hashable, Codable, Identifiable {
  public let rawValue: UUID

  public var id: UUID { rawValue }

  public init(rawValue: UUID = UUID()) {
    self.rawValue = rawValue
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    rawValue = try container.decode(UUID.self)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
