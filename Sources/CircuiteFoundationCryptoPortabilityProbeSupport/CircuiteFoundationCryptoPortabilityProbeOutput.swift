import CircuiteFoundation
import CircuiteFoundationCrypto

public enum CircuiteFoundationCryptoPortabilityProbeOutput {
  public static func make() throws -> String {
    let result: ContentDigestResult
    do {
      result = try SHA256ContentDigester().digest(
        using: .sha256,
        limits: ContentDigestSessionLimits(
          maximumChunkByteCount: 3,
          maximumTotalByteCount: 3,
          maximumUpdateCount: 1
        )
      ) { (lease: borrowing ContentDigestUpdateLease) throws(ContentDigestError) in
        try lease.update([0x61, 0x62, 0x63])
      }
    } catch ContentDigestError.backendUnavailable(let reason) {
      return [
        "CircuiteFoundationCryptoPortabilityProbe",
        "unsupported",
        reason,
      ].joined(separator: ":")
    }
    guard result.digest.hexadecimalValue
            == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
          result.totalByteCount == 3,
          result.updateCount == 1 else {
      throw CryptoPortabilityProbeError.digestMismatch
    }
    return [
      "CircuiteFoundationCryptoPortabilityProbe",
      result.digest.algorithm.rawValue,
      result.digest.hexadecimalValue,
    ].joined(separator: ":")
  }
}

private enum CryptoPortabilityProbeError: Error {
  case digestMismatch
}
