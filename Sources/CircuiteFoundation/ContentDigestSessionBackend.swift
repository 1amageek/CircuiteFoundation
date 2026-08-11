package protocol ContentDigestSessionBackend: AnyObject {
  func update(_ bytes: borrowing [UInt8]) throws(ContentDigestError)
  func finalize() throws(ContentDigestError) -> ContentDigest
  func abort() throws(ContentDigestError)
}
