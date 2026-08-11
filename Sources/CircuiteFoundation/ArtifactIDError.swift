public enum ArtifactIDError: Error, Sendable, Equatable {
  case algorithmTokenTooLong(actual: Int)
  case digestTooLong(actual: Int)
  case invalidCanonicalEncoding
  case invalidDomain
  case unsupportedVersion
  case invalidAlgorithmEncoding
  case invalidDigestAlgorithm(TokenError)
  case invalidDigest(ContentDigestError)
  case truncatedEncoding
  case trailingBytes
}
