public struct ContentDigestUpdateLease: ~Copyable {
  private let session: ContentDigestSessionState

  package init(session: ContentDigestSessionState) {
    self.session = session
  }

  public borrowing func update(
    _ bytes: borrowing [UInt8]
  ) throws(ContentDigestError) {
    try session.update(bytes)
  }
}
