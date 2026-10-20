import CircuiteFoundation
import Foundation

public extension ContentDigesting {
  /// Costs only this adapter's UInt8 copy; backend scratch/result are separate.
  func foundationDataCopyCost(byteCount: UInt64) throws(ContentDigestError)
    -> (temporaryByteCount: UInt64, workUnits: UInt64) {
    guard byteCount <= UInt64(Int.max) else { throw .byteCountOverflow }
    let (temporary, overflow) = byteCount.addingReportingOverflow(UInt64(MemoryLayout<[UInt8]>.stride))
    guard !overflow else { throw .byteCountOverflow }
    return (temporary, byteCount)
  }

  func digest(
    data: Data,
    using algorithm: ContentDigestAlgorithm = .sha256
  ) throws -> ContentDigest {
    let bytes = [UInt8](data)
    let limits = try ContentDigestSessionLimits(
      maximumChunkByteCount: max(UInt64(bytes.count), 1),
      maximumTotalByteCount: max(UInt64(bytes.count), 1),
      maximumUpdateCount: 1
    )
    return try digest(using: algorithm, limits: limits) {
      (lease: borrowing ContentDigestUpdateLease) throws(ContentDigestError) in
      try lease.update(bytes)
    }.digest
  }

  func digest(
    fileAt url: URL,
    using algorithm: ContentDigestAlgorithm = .sha256
  ) throws -> ContentDigest {
    let handle: FileHandle
    do {
      handle = try FileHandle(forReadingFrom: url)
    } catch {
      throw ContentDigestFoundationError.unreadableFile(
        url,
        reason: error.localizedDescription
      )
    }
    defer { handle.closeFile() }

    let limits = try ContentDigestSessionLimits(
      maximumChunkByteCount: 1_048_576,
      maximumTotalByteCount: UInt64.max,
      maximumUpdateCount: UInt64.max
    )
    return try digest(using: algorithm, limits: limits) {
      (lease: borrowing ContentDigestUpdateLease) throws(ContentDigestError) in
      while true {
        let chunk: Data
        do {
          chunk = try handle.read(upToCount: 1_048_576) ?? Data()
        } catch {
          throw ContentDigestError.backendUpdateFailed(reason: error.localizedDescription)
        }
        guard !chunk.isEmpty else { break }
        try lease.update([UInt8](chunk))
      }
    }.digest
  }
}
