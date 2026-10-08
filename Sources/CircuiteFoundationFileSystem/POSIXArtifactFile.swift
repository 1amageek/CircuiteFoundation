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
      do { try close(descriptor) }
      catch { throw POSIXArtifactFileError.cleanupFailed(primary: reason, closeReason: String(describing: error)) }
      throw POSIXArtifactFileError.invalidRoot(reason)
    }
    return descriptor
  }

  static func openFile(
    relativePath: ArtifactRelativePath,
    rootDescriptor: Int32
  ) throws -> Int32 {
    try openRetainedFile(relativePath: relativePath, rootDescriptor: rootDescriptor).descriptor
  }

  static func openRetainedFile(
    relativePath: ArtifactRelativePath, rootDescriptor: Int32,
    accounting: SourceDiscoveryAccounting? = nil
  ) throws -> SourceDiscoveryDescriptor {
    try accounting?.charge(.init(workUnits: 1))
    var currentRetention = try accounting?.retain(.openResources(1))
    let initialDescriptor = withExtendedLifetime(currentRetention) {
      fcntl(rootDescriptor, F_DUPFD_CLOEXEC, 0)
    }
    guard initialDescriptor >= 0 else {
      throw POSIXArtifactFileError.openFailed(
        componentIndex: 0,
        reason: POSIXArtifactFileError.currentReason()
      )
    }
    var currentDescriptor = initialDescriptor

    for (index, component) in relativePath.segments.enumerated() {
      let isFinal = index == relativePath.segments.count - 1
      let flags = O_RDONLY | O_CLOEXEC | O_NOFOLLOW | (isFinal ? O_NONBLOCK : O_DIRECTORY)
      let nextRetention: (any ArtifactSourceRetention)?
      let nameRetention: (any ArtifactSourceRetention)?
      do {
        try accounting?.charge(.init(workUnits: isFinal ? 2 : 1))
        nextRetention = try accounting?.retain(.openResources(1))
        nameRetention = try accounting?.retain(.temporaryBytes(UInt64(component.utf8.count) + 1))
      } catch let primary {
        return try SourceDiscoveryAccounting.closing(currentDescriptor, retention: currentRetention) {
          () throws(ArtifactSourceDiscoveryError) in throw primary
        }
      }
      defer { withExtendedLifetime(nameRetention) {} }
      let nextDescriptor = withExtendedLifetime(nextRetention) {
        component.withCString { Darwin.openat(currentDescriptor, $0, flags) }
      }
      if nextDescriptor < 0 {
        let capturedError = errno
        let primaryReason = String(cString: strerror(capturedError))
        do { try withExtendedLifetime(currentRetention) { try close(currentDescriptor) } }
        catch {
          throw POSIXArtifactFileError.cleanupFailed(primary: primaryReason,
                                                     closeReason: String(describing: error))
        }
        if capturedError == ELOOP {
          throw POSIXArtifactFileError.symlinkTraversal(componentIndex: index)
        }
        errno = capturedError
        throw POSIXArtifactFileError.openFailed(
          componentIndex: index,
          reason: POSIXArtifactFileError.currentReason()
        )
      }
      let closeResult = withExtendedLifetime(currentRetention) { Darwin.close(currentDescriptor) }
      guard closeResult == 0 else {
        let reason = POSIXArtifactFileError.currentReason()
        do { try withExtendedLifetime(nextRetention) { try close(nextDescriptor) } }
        catch {
          throw POSIXArtifactFileError.cleanupFailed(primary: reason,
                                                     closeReason: String(describing: error))
        }
        throw POSIXArtifactFileError.closeFailed(reason)
      }
      currentDescriptor = nextDescriptor
      currentRetention = nextRetention
    }
    return SourceDiscoveryDescriptor(descriptor: currentDescriptor, retention: currentRetention)
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
