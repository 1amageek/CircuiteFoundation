import Foundation
import Testing

func withTemporaryDirectory<Result>(
  _ operation: (URL) throws -> Result
) throws -> Result {
  let directory = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
  try FileManager.default.createDirectory(
    at: directory,
    withIntermediateDirectories: true
  )

  do {
    let result = try operation(directory)
    try FileManager.default.removeItem(at: directory)
    return result
  } catch {
    do {
      try FileManager.default.removeItem(at: directory)
    } catch let cleanupError {
      Issue.record("Temporary directory cleanup failed: \(cleanupError)")
    }
    throw error
  }
}
