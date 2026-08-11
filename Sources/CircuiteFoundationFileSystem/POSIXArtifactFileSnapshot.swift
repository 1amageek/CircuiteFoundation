import Darwin

struct POSIXArtifactFileSnapshot: Equatable, Sendable {
  let device: UInt64
  let inode: UInt64
  let byteCount: UInt64
  let modificationSeconds: Int64
  let modificationNanoseconds: Int64
  let changeSeconds: Int64
  let changeNanoseconds: Int64

  init(fileDescriptor: Int32) throws {
    var information = stat()
    guard fstat(fileDescriptor, &information) == 0 else {
      throw POSIXArtifactFileError.metadataFailed(POSIXArtifactFileError.currentReason())
    }
    guard (information.st_mode & S_IFMT) == S_IFREG else {
      throw POSIXArtifactFileError.notRegularFile
    }
    guard information.st_size >= 0 else {
      throw POSIXArtifactFileError.invalidByteCount
    }
    device = UInt64(information.st_dev)
    inode = UInt64(information.st_ino)
    byteCount = UInt64(information.st_size)
    modificationSeconds = Int64(information.st_mtimespec.tv_sec)
    modificationNanoseconds = Int64(information.st_mtimespec.tv_nsec)
    changeSeconds = Int64(information.st_ctimespec.tv_sec)
    changeNanoseconds = Int64(information.st_ctimespec.tv_nsec)
  }
}
