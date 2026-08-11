public struct ArtifactIntegrityIssue: Sendable, Hashable {
  public enum Code: String, Sendable, Hashable {
    case invalidLocation
    case missingFile
    case notRegularFile
    case byteCountMismatch
    case digestMismatch
    case unreadableFile
    case unsupportedDigestAlgorithm
  }

  public let code: Code
  public let location: String?
  public let detail: String?
  public let expectedByteCount: UInt64?
  public let actualByteCount: UInt64?
  public let expectedDigest: ContentDigest?
  public let actualDigest: ContentDigest?
  public let digestAlgorithm: ContentDigestAlgorithm?

  public static func invalidLocation(_ detail: String) -> Self {
    Self(code: .invalidLocation, detail: detail)
  }

  public static func missingFile(_ location: String) -> Self {
    Self(code: .missingFile, location: location)
  }

  public static func notRegularFile(_ location: String) -> Self {
    Self(code: .notRegularFile, location: location)
  }

  public static func byteCountMismatch(expected: UInt64, actual: UInt64) -> Self {
    Self(
      code: .byteCountMismatch,
      expectedByteCount: expected,
      actualByteCount: actual
    )
  }

  public static func digestMismatch(expected: ContentDigest, actual: ContentDigest) -> Self {
    Self(code: .digestMismatch, expectedDigest: expected, actualDigest: actual)
  }

  public static func unreadableFile(_ detail: String) -> Self {
    Self(code: .unreadableFile, detail: detail)
  }

  public static func unsupportedDigestAlgorithm(_ algorithm: ContentDigestAlgorithm) -> Self {
    Self(code: .unsupportedDigestAlgorithm, digestAlgorithm: algorithm)
  }

  private init(
    code: Code,
    location: String? = nil,
    detail: String? = nil,
    expectedByteCount: UInt64? = nil,
    actualByteCount: UInt64? = nil,
    expectedDigest: ContentDigest? = nil,
    actualDigest: ContentDigest? = nil,
    digestAlgorithm: ContentDigestAlgorithm? = nil
  ) {
    self.code = code
    self.location = location
    self.detail = detail
    self.expectedByteCount = expectedByteCount
    self.actualByteCount = actualByteCount
    self.expectedDigest = expectedDigest
    self.actualDigest = actualDigest
    self.digestAlgorithm = digestAlgorithm
  }

  package init(
    validatingCode code: Code,
    location: String?,
    detail: String?,
    expectedByteCount: UInt64?,
    actualByteCount: UInt64?,
    expectedDigest: ContentDigest?,
    actualDigest: ContentDigest?,
    digestAlgorithm: ContentDigestAlgorithm?
  ) throws {
    guard Self.hasValidPayload(
      code: code,
      location: location,
      detail: detail,
      expectedByteCount: expectedByteCount,
      actualByteCount: actualByteCount,
      expectedDigest: expectedDigest,
      actualDigest: actualDigest,
      digestAlgorithm: digestAlgorithm
    ) else {
      throw ValidationError.invalidPayload(code)
    }
    self.init(
      code: code,
      location: location,
      detail: detail,
      expectedByteCount: expectedByteCount,
      actualByteCount: actualByteCount,
      expectedDigest: expectedDigest,
      actualDigest: actualDigest,
      digestAlgorithm: digestAlgorithm
    )
  }

  package enum ValidationError: Error {
    case invalidPayload(Code)
  }

  private static func hasValidPayload(
    code: Code,
    location: String?,
    detail: String?,
    expectedByteCount: UInt64?,
    actualByteCount: UInt64?,
    expectedDigest: ContentDigest?,
    actualDigest: ContentDigest?,
    digestAlgorithm: ContentDigestAlgorithm?
  ) -> Bool {
    let hasLocation = location != nil
    let hasDetail = detail != nil
    let hasExpectedByteCount = expectedByteCount != nil
    let hasActualByteCount = actualByteCount != nil
    let hasExpectedDigest = expectedDigest != nil
    let hasActualDigest = actualDigest != nil
    let hasDigestAlgorithm = digestAlgorithm != nil

    switch code {
    case .invalidLocation, .unreadableFile:
      return hasDetail
        && !hasLocation
        && !hasExpectedByteCount
        && !hasActualByteCount
        && !hasExpectedDigest
        && !hasActualDigest
        && !hasDigestAlgorithm
    case .missingFile, .notRegularFile:
      return hasLocation
        && !hasDetail
        && !hasExpectedByteCount
        && !hasActualByteCount
        && !hasExpectedDigest
        && !hasActualDigest
        && !hasDigestAlgorithm
    case .byteCountMismatch:
      return !hasLocation
        && !hasDetail
        && hasExpectedByteCount
        && hasActualByteCount
        && !hasExpectedDigest
        && !hasActualDigest
        && !hasDigestAlgorithm
    case .digestMismatch:
      return !hasLocation
        && !hasDetail
        && !hasExpectedByteCount
        && !hasActualByteCount
        && hasExpectedDigest
        && hasActualDigest
        && !hasDigestAlgorithm
    case .unsupportedDigestAlgorithm:
      return !hasLocation
        && !hasDetail
        && !hasExpectedByteCount
        && !hasActualByteCount
        && !hasExpectedDigest
        && !hasActualDigest
        && hasDigestAlgorithm
    }
  }
}
