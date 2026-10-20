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

  /// Managed payload of this fixed SHA-256 implementation, excluding backend-private
  /// allocator workspace and caller input bytes. Retain the 64-byte result backing.
  public static func managedCost(byteCount: UInt64) throws(ContentDigestError)
    -> (temporaryByteCount: UInt64, retainedByteCount: UInt64, workUnits: UInt64) {
    guard byteCount <= UInt64(Int.max) else { throw .byteCountOverflow }
#if CIRCUITE_FOUNDATION_NO_CRYPTO_BACKEND
    throw .backendUnavailable(reason: "The pinned WASI runtime has no qualified SHA-256 backend.")
#else
#if canImport(CryptoKit) || canImport(Crypto)
    // Digit table16, reserved hex buffer64, original String64. The normalized
    // returned String64 is separate retained storage, not temporary duplication.
    let fixed = UInt64(16 + 64 + 64 + MemoryLayout<[UInt8]>.stride * 2
      + MemoryLayout<String>.stride + ContentDigestSessionState.managedPayloadByteCount
      + MemoryLayout<(SHA256, Bool)>.stride)
    // Hash input plus named finalize visits: digit table16, digest32, hex writes64,
    // String materialization64, ASCII lowercase64 and hex validation64.
    let (work, overflow) = byteCount.addingReportingOverflow(16 + 32 + 64 + 64 + 64 + 64)
    guard !overflow else { throw .byteCountOverflow }
    return (fixed, 64, work)
#else
    throw .backendUnavailable(reason: "No SHA-256 implementation is linked for this target.")
#endif
#endif
  }

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
