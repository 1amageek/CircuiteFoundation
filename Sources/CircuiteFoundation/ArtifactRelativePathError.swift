public enum ArtifactRelativePathError: Error, Sendable, Equatable {
  case empty
  case tooManySegments(actual: Int, maximum: Int)
  case emptySegment(index: Int)
  case reservedSegment(index: Int, value: String)
  case separatorInSegment(index: Int, value: String)
  case controlCharacterInSegment(index: Int, value: String)
  case segmentTooLong(index: Int, actualUTF8ByteCount: Int, maximum: Int)
}
