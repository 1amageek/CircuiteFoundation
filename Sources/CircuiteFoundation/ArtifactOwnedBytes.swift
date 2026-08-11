public protocol ArtifactOwnedBytes: Sendable {
  var byteCount: UInt64 { get }

  func withUnsafeBytes<Result>(
    _ body: (UnsafeRawBufferPointer) throws -> Result
  ) rethrows -> Result
}
