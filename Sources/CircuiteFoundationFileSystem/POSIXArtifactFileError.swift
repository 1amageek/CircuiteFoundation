import Darwin

enum POSIXArtifactFileError: Error {
  case invalidRoot(String)
  case metadataFailed(String)
  case notRegularFile
  case invalidByteCount
  case openFailed(componentIndex: Int, reason: String)
  case symlinkTraversal(componentIndex: Int)
  case readFailed(String)
  case shortRead(expected: Int, actual: Int)
  case offsetOverflow
  case closeFailed(String)

  static func currentReason() -> String {
    String(cString: strerror(errno))
  }
}
