import CircuiteFoundation
#if CIRCUITE_FOUNDATION_NO_CRYPTO_BACKEND
#else
#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif
#endif

public struct SHA256ContentDigester: ContentDigesting {
  public init() {}

  public func digest(
    using algorithm: ContentDigestAlgorithm,
    limits: ContentDigestSessionLimits,
    _ body: (borrowing ContentDigestUpdateLease) throws(ContentDigestError) -> Void
  ) throws(ContentDigestError) -> ContentDigestResult {
    guard algorithm == .sha256 else {
      throw .unsupportedAlgorithm(algorithm)
    }
#if CIRCUITE_FOUNDATION_NO_CRYPTO_BACKEND
    throw .backendUnavailable(
      reason: "The pinned WASI runtime has no qualified SHA-256 backend."
    )
#else
#if canImport(CryptoKit) || canImport(Crypto)
    return try ContentDigestSessionRunner.run(
      backend: SHA256ContentDigestSessionBackend(),
      limits: limits,
      body
    )
#else
    throw .backendUnavailable(
      reason: "No SHA-256 implementation is linked for this target."
    )
#endif
#endif
  }
}

#if CIRCUITE_FOUNDATION_NO_CRYPTO_BACKEND
#else
#if canImport(CryptoKit) || canImport(Crypto)
private final class SHA256ContentDigestSessionBackend: ContentDigestSessionBackend {
  private var hasher = SHA256()
  private var isActive = true

  func update(_ bytes: borrowing [UInt8]) throws(ContentDigestError) {
    guard isActive else {
      throw .sessionStateViolation
    }
    hasher.update(data: bytes)
  }

  func finalize() throws(ContentDigestError) -> ContentDigest {
    guard isActive else {
      throw .sessionStateViolation
    }
    isActive = false
    let digest = hasher.finalize()
    let digits = Array("0123456789abcdef".utf8)
    var bytes: [UInt8] = []
    bytes.reserveCapacity(64)
    for byte in digest {
      bytes.append(digits[Int(byte >> 4)])
      bytes.append(digits[Int(byte & 0x0f)])
    }
    let value = String(decoding: bytes, as: UTF8.self)
    do {
      return try ContentDigest(algorithm: .sha256, hexadecimalValue: value)
    } catch {
      throw .finalizationFailed(reason: String(describing: error))
    }
  }

  func abort() throws(ContentDigestError) {
    isActive = false
  }
}
#endif
#endif
