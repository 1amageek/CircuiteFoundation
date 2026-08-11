public struct ArtifactReadPageRequest: Sendable, Hashable {
  public let offset: UInt64
  public let maximumByteCount: UInt64

  public init(
    offset: UInt64,
    maximumByteCount: UInt64
  ) throws {
    guard maximumByteCount > 0 else {
      throw ArtifactReadPageRequestError.zeroMaximumByteCount
    }
    self.offset = offset
    self.maximumByteCount = maximumByteCount
  }

}
