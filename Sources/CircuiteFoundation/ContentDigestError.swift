public enum ContentDigestError: Error, Sendable, Equatable {
  case emptyHexadecimalValue
  case invalidHexadecimalValue(String)
  case incompleteByte(String)
  case invalidLength(algorithm: ContentDigestAlgorithm, actual: Int, expected: Int)
  case invalidLimits(ContentDigestSessionLimits)
  case unsupportedAlgorithm(ContentDigestAlgorithm)
  case chunkByteLimitExceeded(limit: UInt64, requested: UInt64)
  case totalByteLimitExceeded(limit: UInt64, requested: UInt64)
  case updateCountLimitExceeded(limit: UInt64, requested: UInt64)
  case byteCountOverflow
  case sessionStateViolation
  case backendUnavailable(reason: String)
  case backendUpdateFailed(reason: String)
  case finalizationFailed(reason: String)
  indirect case abortFailed(primary: ContentDigestError, abort: ContentDigestError)

  public var errorDescription: String? {
    switch self {
    case .emptyHexadecimalValue:
      "A content digest cannot be empty."
    case .invalidHexadecimalValue(let value):
      "Content digest contains non-hexadecimal characters: \(value)"
    case .incompleteByte(let value):
      "Content digest must contain complete hexadecimal bytes: \(value)"
    case .invalidLength(let algorithm, let actual, let expected):
      "Digest for \(algorithm.rawValue) contains \(actual) hexadecimal characters; expected \(expected)."
    case .invalidLimits:
      "Content digest session limits must all be nonzero."
    case .unsupportedAlgorithm(let algorithm):
      "Unsupported content digest algorithm: \(algorithm.rawValue)"
    case .chunkByteLimitExceeded(let limit, let requested):
      "Content digest chunk byte limit \(limit) was exceeded by request \(requested)."
    case .totalByteLimitExceeded(let limit, let requested):
      "Content digest total byte limit \(limit) was exceeded by request \(requested)."
    case .updateCountLimitExceeded(let limit, let requested):
      "Content digest update-count limit \(limit) was exceeded by request \(requested)."
    case .byteCountOverflow:
      "Content digest byte accounting overflowed."
    case .sessionStateViolation:
      "Content digest session was used outside its active scope."
    case .backendUnavailable(let reason):
      "Content digest backend is unavailable: \(reason)"
    case .backendUpdateFailed(let reason):
      "Content digest backend update failed: \(reason)"
    case .finalizationFailed(let reason):
      "Content digest finalization failed: \(reason)"
    case .abortFailed(let primary, let abort):
      "Content digest abort failed after \(primary.errorDescription ?? "unknown primary failure"): \(abort.errorDescription ?? "unknown abort failure")"
    }
  }
}
