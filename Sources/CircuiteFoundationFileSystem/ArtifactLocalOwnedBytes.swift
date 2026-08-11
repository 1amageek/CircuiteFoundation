import CircuiteFoundation

struct ArtifactLocalOwnedBytes: ArtifactOwnedBytes {
  let storage: [UInt8]

  var byteCount: UInt64 {
    UInt64(storage.count)
  }

  func withUnsafeBytes<Result>(
    _ body: (UnsafeRawBufferPointer) throws -> Result
  ) rethrows -> Result {
    try storage.withUnsafeBytes(body)
  }
}
