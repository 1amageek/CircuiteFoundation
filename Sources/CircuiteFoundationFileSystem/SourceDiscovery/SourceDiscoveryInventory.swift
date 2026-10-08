import CircuiteFoundation
import Darwin
import Foundation

struct SourceDiscoveryInventory {
  let intent: ArtifactDirectoryInventoryIntent
  let accounting: SourceDiscoveryAccounting
  var visited: UInt64 = 0
  var work: UInt64 = 0
  var entries: [ArtifactDirectoryEntry] = []

  var progress: ArtifactDirectoryInventoryProgress {
    .init(visitedEntryCount: visited, resultCount: UInt64(entries.count), workUnitCount: work)
  }

  static func enumerate(_ intent: ArtifactDirectoryInventoryIntent, rootDescriptor: Int32,
                        control: (any ArtifactSourceControl)? = nil)
    throws(ArtifactSourceDiscoveryError) -> ArtifactDirectoryInventory {
    var walker = Self(intent: intent, accounting: SourceDiscoveryAccounting(
      maximumDurationNanoseconds: intent.maximumDurationNanoseconds, control: control))
    try walker.charge(3) // Root acquisition, directory stream ownership, final close.
    if let start = intent.start { try walker.charge(UInt64(start.segments.count) + 1) }
    let opened: SourceDiscoveryDescriptor
    do {
      if let start = intent.start {
        opened = try POSIXArtifactFile.openRetainedFile(relativePath: start,
          rootDescriptor: rootDescriptor, accounting: walker.accounting)
      } else {
        // dup shares the directory offset; opening dot gives each inventory its own cursor.
        let retention = try walker.accounting.retain(.openResources(1))
        let descriptor = withExtendedLifetime(retention) {
          openat(rootDescriptor, ".", O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        }
        guard descriptor >= 0 else {
          throw POSIXArtifactFileError.openFailed(componentIndex: 0,
            reason: POSIXArtifactFileError.currentReason())
        }
        opened = .init(descriptor: descriptor, retention: retention)
      }
    } catch let error as ArtifactSourceDiscoveryError { throw error }
    catch { throw .access(ArtifactRootCapability.mapFileError(error)) }
    try walker.walk(opened: opened, segments: intent.start?.segments ?? [], depth: 0)
    try walker.sortEntries()
    try walker.accounting.check(progress: walker.progress)
    return ArtifactDirectoryInventory(entries: walker.entries, progress: walker.progress,
      work: .init(pageCount: 0, workUnitCount: walker.work,
                  elapsedNanoseconds: walker.accounting.elapsedNanoseconds))
  }

  mutating func charge(_ amount: UInt64 = 1) throws(ArtifactSourceDiscoveryError) {
    try accounting.check(progress: progress)
    let next = work.addingReportingOverflow(amount)
    guard !next.overflow, next.partialValue <= intent.maximumWorkUnitCount else {
      throw .workLimitExceeded(limit: intent.maximumWorkUnitCount, progress: progress)
    }
    try accounting.charge(.init(workUnits: amount))
    work = next.partialValue
  }

  mutating func walk(opened: SourceDiscoveryDescriptor, segments: [String], depth: UInt64)
    throws(ArtifactSourceDiscoveryError) {
    defer { withExtendedLifetime(opened.retention) {} }
    guard let directory = fdopendir(opened.descriptor) else {
      let primary = ArtifactSourceDiscoveryError.inventoryFailed(
        reason: POSIXArtifactFileError.currentReason(), progress: progress)
      _ = try SourceDiscoveryAccounting.closing(opened.descriptor, retention: opened.retention) { () throws(ArtifactSourceDiscoveryError) in
        throw primary
      }
      return
    }
    // fdopendir owns this descriptor. No pointer or directory stream escapes this stack frame.
    let result: Result<Void, ArtifactSourceDiscoveryError>
    do {
      try scan(directory: directory, segments: segments, depth: depth)
      result = .success(())
    } catch { result = .failure(error) }
    guard closedir(directory) == 0 else {
      let primary: ArtifactSourceDiscoveryError?
      switch result { case .success: primary = nil; case .failure(let error): primary = error }
      throw .cleanupFailed(primary: primary, closeReason: POSIXArtifactFileError.currentReason())
    }
    switch result { case .success: break; case .failure(let error): throw error }
  }

  mutating func scan(directory: UnsafeMutablePointer<DIR>, segments: [String], depth: UInt64)
    throws(ArtifactSourceDiscoveryError) {
    while true {
      try charge() // Includes the terminal readdir call.
      errno = 0
      guard let record = readdir(directory) else {
        guard errno == 0 else {
          throw .inventoryFailed(reason: POSIXArtifactFileError.currentReason(), progress: progress)
        }
        return
      }
      let nextVisited = visited.addingReportingOverflow(1)
      guard !nextVisited.overflow else {
        throw .entryLimitExceeded(limit: intent.maximumVisitedEntryCount, progress: progress)
      }
      try accounting.charge(.init(visitedEntries: 1))
      visited = nextVisited.partialValue
      guard visited <= intent.maximumVisitedEntryCount else {
        throw .entryLimitExceeded(limit: intent.maximumVisitedEntryCount, progress: progress)
      }
      // Count dot entries and invalid UTF-8/names before rejecting them.
      let nameCount = Int(record.pointee.d_namlen)
      try charge(UInt64(nameCount))
      let nameRetention = try accounting.retain(.ownedBytes(UInt64(nameCount)))
      defer { withExtendedLifetime(nameRetention) {} }
      // Darwin retains this record until the next readdir; borrow only its declared tuple storage.
      let name = withUnsafeBytes(of: &record.pointee.d_name) { buffer -> String? in
        guard nameCount < buffer.count else { return nil }
        return String(bytes: buffer.prefix(nameCount), encoding: .utf8)
      }
      guard let name, name != ".", name != ".." else { continue }
      var pathBytes = try SourceDiscoveryAccounting.byteExtent(UInt64(segments.count) + 1,
        stride: MemoryLayout<String>.stride, resource: .ownedBytes)
      // Each escaped entry owns a complete logical path extent even when strings share backing.
      for segment in segments {
        pathBytes = try SourceDiscoveryAccounting.sum(pathBytes, UInt64(segment.utf8.count), resource: .ownedBytes)
      }
      let pathRetention = try accounting.retain(.ownedBytes(pathBytes))
      defer { withExtendedLifetime(pathRetention) {} }
      let path: ArtifactRelativePath
      do { path = try ArtifactRelativePath(segments: segments + [name]) }
      catch { continue }
      try charge()
      let cNameRetention = try accounting.retain(.temporaryBytes(UInt64(nameCount) + 1))
      defer { withExtendedLifetime(cNameRetention) {} }
      var information = stat()
      guard name.withCString({ fstatat(dirfd(directory), $0, &information, AT_SYMLINK_NOFOLLOW) }) == 0 else {
        throw .inventoryFailed(reason: POSIXArtifactFileError.currentReason(), progress: progress)
      }
      let kind: ArtifactDirectoryEntry.Kind
      switch information.st_mode & S_IFMT {
      case S_IFREG: kind = .regularFile
      case S_IFDIR: kind = .directory
      case S_IFLNK: kind = .symbolicLink
      default: kind = .other
      }
      guard UInt64(entries.count) < intent.maximumResultCount else {
        throw .resultLimitExceeded(limit: intent.maximumResultCount, progress: progress)
      }
      let retainedSlots = try SourceDiscoveryAccounting.byteExtent(3,
        stride: MemoryLayout<any ArtifactSourceRetention>.stride, resource: .ownedBytes)
      let entryBytes = try SourceDiscoveryAccounting.sum(UInt64(MemoryLayout<ArtifactDirectoryEntry>.stride),
        retainedSlots, resource: .ownedBytes)
      let entryRetention = try accounting.retain(.ownedBytes(entryBytes))
      var retentions: [any ArtifactSourceRetention] = []
      retentions.reserveCapacity(3)
      if let nameRetention { retentions.append(nameRetention) }
      if let pathRetention { retentions.append(pathRetention) }
      if let entryRetention { retentions.append(entryRetention) }
      entries.append(.init(relativePath: path, kind: kind, retentions: retentions))
      if kind == .directory {
        guard depth < intent.maximumDepth else {
          throw .depthLimitExceeded(limit: intent.maximumDepth, progress: progress)
        }
        try charge(3) // Child open, directory stream ownership and eventual close.
        let childRetention = try accounting.retain(.openResources(1))
        let child = withExtendedLifetime(childRetention) {
          name.withCString {
            openat(dirfd(directory), $0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
          }
        }
        guard child >= 0 else {
          throw .inventoryFailed(reason: POSIXArtifactFileError.currentReason(), progress: progress)
        }
        try walk(opened: .init(descriptor: child, retention: childRetention),
                 segments: path.segments, depth: depth + 1)
      }
    }
  }

  private func keyByteCount(_ path: ArtifactRelativePath) throws(ArtifactSourceDiscoveryError) -> UInt64 {
    var count = UInt64(path.segments.count - 1)
    for segment in path.segments {
      count = try SourceDiscoveryAccounting.sum(count, UInt64(segment.utf8.count), resource: .temporaryBytes)
    }
    return count
  }

  mutating func sortEntries() throws(ArtifactSourceDiscoveryError) {
    // Bottom-up merge sorting bounds both auxiliary storage and comparison work.
    var width = 1
    while width < entries.count {
      let outputBytes = try SourceDiscoveryAccounting.byteExtent(UInt64(entries.count),
        stride: MemoryLayout<ArtifactDirectoryEntry>.stride, resource: .temporaryBytes)
      let outputRetention = try accounting.retain(.temporaryBytes(outputBytes))
      defer { withExtendedLifetime(outputRetention) {} }
      var output: [ArtifactDirectoryEntry] = []
      output.reserveCapacity(entries.count)
      var start = 0
      while start < entries.count {
        let middle = min(start + width, entries.count)
        let end = min(middle + width, entries.count)
        var left = start
        var right = middle
        while left < middle && right < end {
          let lhsCount = try keyByteCount(entries[left].relativePath)
          let rhsCount = try keyByteCount(entries[right].relativePath)
          let keyBytes = try SourceDiscoveryAccounting.sum(lhsCount, rhsCount, resource: .temporaryBytes)
          try charge(try SourceDiscoveryAccounting.sum(keyBytes, 1, resource: .workUnits))
          let keyRetention = try accounting.retain(.temporaryBytes(keyBytes))
          defer { withExtendedLifetime(keyRetention) {} }
          let lhs = entries[left].relativePath.segments.joined(separator: "/")
          let rhs = entries[right].relativePath.segments.joined(separator: "/")
          if lhs.utf8.lexicographicallyPrecedes(rhs.utf8) {
            output.append(entries[left]); left += 1
          } else { output.append(entries[right]); right += 1 }
        }
        while left < middle { try charge(); output.append(entries[left]); left += 1 }
        while right < end { try charge(); output.append(entries[right]); right += 1 }
        start = end
      }
      entries = output
      width = width > entries.count / 2 ? entries.count : width * 2
    }
  }
}
