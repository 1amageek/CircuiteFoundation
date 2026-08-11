public struct ContentDigestSessionLimits: Sendable, Hashable {
  public let maximumChunkByteCount: UInt64
  public let maximumTotalByteCount: UInt64
  public let maximumUpdateCount: UInt64

  public init(
    maximumChunkByteCount: UInt64,
    maximumTotalByteCount: UInt64,
    maximumUpdateCount: UInt64
  ) throws(ContentDigestError) {
    self.maximumChunkByteCount = maximumChunkByteCount
    self.maximumTotalByteCount = maximumTotalByteCount
    self.maximumUpdateCount = maximumUpdateCount
    guard maximumChunkByteCount > 0,
          maximumTotalByteCount > 0,
          maximumUpdateCount > 0 else {
      throw .invalidLimits(self)
    }
  }

  public static var singleBufferMaximum: Self {
    get throws(ContentDigestError) {
      try Self(
        maximumChunkByteCount: UInt64.max,
        maximumTotalByteCount: UInt64.max,
        maximumUpdateCount: 1
      )
    }
  }

}
