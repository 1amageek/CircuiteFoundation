public protocol ContentDigesting: Sendable {
  func digest(
    using algorithm: ContentDigestAlgorithm,
    limits: ContentDigestSessionLimits,
    _ body: (borrowing ContentDigestUpdateLease) throws(ContentDigestError) -> Void
  ) throws(ContentDigestError) -> ContentDigestResult
}
