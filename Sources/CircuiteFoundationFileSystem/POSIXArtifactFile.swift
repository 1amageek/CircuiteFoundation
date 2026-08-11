import CircuiteFoundation
import Darwin
import Foundation

enum POSIXArtifactFile {
  static func openRoot(at url: URL) throws -> Int32 {
    let descriptor = url.path.withCString {
      Darwin.open($0, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
    }
    guard descriptor >= 0 else {
      throw POSIXArtifactFileError.invalidRoot(POSIXArtifactFileError.currentReason())
    }
    var information = stat()
    guard fstat(descriptor, &information) == 0,
          (information.st_mode & S_IFMT) == S_IFDIR else {
      let reason = POSIXArtifactFileError.currentReason()
      _ = Darwin.close(descriptor)
      throw POSIXArtifactFileError.invalidRoot(reason)
    }
    return descriptor
  }

  static func openFile(
    relativePath: ArtifactRelativePath,
    rootDescriptor: Int32
  ) throws -> Int32 {
    let initialDescriptor = dup(rootDescriptor)
    guard initialDescriptor >= 0 else {
      throw POSIXArtifactFileError.openFailed(
        componentIndex: 0,
        reason: POSIXArtifactFileError.currentReason()
      )
    }
    var currentDescriptor = initialDescriptor

    for (index, component) in relativePath.segments.enumerated() {
      let isFinal = index == relativePath.segments.count - 1
      let flags = O_RDONLY | O_CLOEXEC | O_NOFOLLOW | (isFinal ? 0 : O_DIRECTORY)
      let nextDescriptor = component.withCString {
        Darwin.openat(currentDescriptor, $0, flags)
      }
      if nextDescriptor < 0 {
        let capturedError = errno
        _ = Darwin.close(currentDescriptor)
        if capturedError == ELOOP {
          throw POSIXArtifactFileError.symlinkTraversal(componentIndex: index)
        }
        errno = capturedError
        throw POSIXArtifactFileError.openFailed(
          componentIndex: index,
          reason: POSIXArtifactFileError.currentReason()
        )
      }
      let closeResult = Darwin.close(currentDescriptor)
      guard closeResult == 0 else {
        let reason = POSIXArtifactFileError.currentReason()
        _ = Darwin.close(nextDescriptor)
        throw POSIXArtifactFileError.closeFailed(reason)
      }
      currentDescriptor = nextDescriptor
    }
    return currentDescriptor
  }

  static func read(
    fileDescriptor: Int32,
    offset: UInt64,
    byteCount: Int
  ) throws -> [UInt8] {
    guard offset <= UInt64(Int64.max) else {
      throw POSIXArtifactFileError.offsetOverflow
    }
    var bytes = [UInt8](repeating: 0, count: byteCount)
    let readCount = bytes.withUnsafeMutableBytes { buffer in
      pread(fileDescriptor, buffer.baseAddress, byteCount, off_t(offset))
    }
    guard readCount >= 0 else {
      throw POSIXArtifactFileError.readFailed(POSIXArtifactFileError.currentReason())
    }
    guard readCount == byteCount else {
      throw POSIXArtifactFileError.shortRead(expected: byteCount, actual: readCount)
    }
    return bytes
  }

  static func close(_ fileDescriptor: Int32) throws {
    guard Darwin.close(fileDescriptor) == 0 else {
      throw POSIXArtifactFileError.closeFailed(POSIXArtifactFileError.currentReason())
    }
  }
}
