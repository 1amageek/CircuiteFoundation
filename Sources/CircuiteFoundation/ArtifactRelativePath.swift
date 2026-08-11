public struct ArtifactRelativePath: Sendable, Hashable {
  public let segments: [String]

  public var stringValue: String {
    segments.joined(separator: "/")
  }

  public init(segments: [String]) throws {
    guard !segments.isEmpty else {
      throw ArtifactRelativePathError.empty
    }
    guard segments.count <= Int(UInt16.max) else {
      throw ArtifactRelativePathError.tooManySegments(
        actual: segments.count,
        maximum: Int(UInt16.max)
      )
    }
    for (index, segment) in segments.enumerated() {
      guard !segment.isEmpty else {
        throw ArtifactRelativePathError.emptySegment(index: index)
      }
      guard segment != ".", segment != ".." else {
        throw ArtifactRelativePathError.reservedSegment(index: index, value: segment)
      }
      guard !segment.contains("/"), !segment.contains("\\") else {
        throw ArtifactRelativePathError.separatorInSegment(index: index, value: segment)
      }
      guard !segment.unicodeScalars.contains(where: { $0.value < 0x20 || $0.value == 0x7f }) else {
        throw ArtifactRelativePathError.controlCharacterInSegment(index: index, value: segment)
      }
      let byteCount = segment.utf8.count
      guard byteCount <= Int(UInt16.max) else {
        throw ArtifactRelativePathError.segmentTooLong(
          index: index,
          actualUTF8ByteCount: byteCount,
          maximum: Int(UInt16.max)
        )
      }
    }
    self.segments = segments
  }

}
