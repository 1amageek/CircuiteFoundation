import Foundation

public protocol ContentDigesting: Sendable {
  func digest(
    data: Data,
    using algorithm: ContentDigestAlgorithm
  ) throws -> ContentDigest

  func digest(
    fileAt url: URL,
    using algorithm: ContentDigestAlgorithm
  ) throws -> ContentDigest
}
