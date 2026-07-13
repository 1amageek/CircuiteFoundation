import CryptoKit
import Foundation

public struct SHA256ContentDigester: ContentDigesting {
  public init() {}

  public func digest(
    data: Data,
    using algorithm: ContentDigestAlgorithm = .sha256
  ) throws -> ContentDigest {
    try validate(algorithm)
    let digest = SHA256.hash(data: data)
    return try ContentDigest(
      algorithm: .sha256,
      hexadecimalValue: digest.map { String(format: "%02x", $0) }.joined()
    )
  }

  public func digest(
    fileAt url: URL,
    using algorithm: ContentDigestAlgorithm = .sha256
  ) throws -> ContentDigest {
    try validate(algorithm)

    let handle: FileHandle
    do {
      handle = try FileHandle(forReadingFrom: url)
    } catch {
      throw ContentDigestError.unreadableFile(url, reason: error.localizedDescription)
    }
    defer { handle.closeFile() }

    var hasher = SHA256()
    while true {
      let chunk: Data
      do {
        chunk = try handle.read(upToCount: 1_048_576) ?? Data()
      } catch {
        throw ContentDigestError.unreadableFile(url, reason: error.localizedDescription)
      }
      guard !chunk.isEmpty else {
        break
      }
      hasher.update(data: chunk)
    }

    let value = hasher.finalize().map { String(format: "%02x", $0) }.joined()
    return try ContentDigest(algorithm: .sha256, hexadecimalValue: value)
  }

  private func validate(_ algorithm: ContentDigestAlgorithm) throws {
    guard algorithm == .sha256 else {
      throw ContentDigestError.unsupportedAlgorithm(algorithm)
    }
  }
}
