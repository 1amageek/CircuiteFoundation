package enum ContentDigestSessionRunner {
  package static func run(
    backend: any ContentDigestSessionBackend,
    limits: ContentDigestSessionLimits,
    _ body: (borrowing ContentDigestUpdateLease) throws(ContentDigestError) -> Void
  ) throws(ContentDigestError) -> ContentDigestResult {
    let session = ContentDigestSessionState(backend: backend, limits: limits)
    let lease = ContentDigestUpdateLease(session: session)
    do {
      try body(lease)
      return try session.finalize()
    } catch {
      throw session.abort(after: error)
    }
  }
}
