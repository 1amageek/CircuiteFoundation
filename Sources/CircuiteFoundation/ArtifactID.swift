import Foundation
import CryptoKit

/// Stable identity for an immutable artifact.
///
/// Artifact identifiers are opaque tokens rather than UUIDs because domain
/// packages already expose stable identifiers such as `design` or
/// `dft-release-result`. Keeping the token preserves identity across
/// Foundation projections and remains compatible with UUID-shaped values.
public struct ArtifactID: Sendable, Hashable, Codable, Identifiable {
  public let rawValue: String

  public var id: String { rawValue }

  public init() {
    self.rawValue = UUID().uuidString
  }

  public init(rawValue: String) throws {
    try TokenValidation.validate(rawValue, kind: "Artifact ID")
    self.rawValue = rawValue
  }

  public init(rawValue: UUID) {
    self.rawValue = rawValue.uuidString
  }

  /// Creates a deterministic identifier for a projection that has no
  /// producer-assigned artifact token.
  public init(stableKey: String) {
    let digest = SHA256.hash(data: Data(stableKey.utf8))
    let hexadecimalValue = digest.map { String(format: "%02x", $0) }.joined()
    self.rawValue = "derived-\(hexadecimalValue)"
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(rawValue: container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
