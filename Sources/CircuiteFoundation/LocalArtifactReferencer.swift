import Foundation

public struct LocalArtifactReferencer: ArtifactReferencing {
  private let digester: any ContentDigesting

  private struct FileSnapshot: Equatable {
    let byteCount: Int64
    let modificationDate: Date?
    let fileNumber: NSNumber?
  }

  public init(digester: any ContentDigesting = SHA256ContentDigester()) {
    self.digester = digester
  }

  public func reference(
    _ locator: ArtifactLocator,
    relativeTo workspaceRoot: URL? = nil,
    producer: ProducerIdentity? = nil
  ) throws -> ArtifactReference {
    let url = try locator.location.resolvedFileURL(relativeTo: workspaceRoot)
    let fileManager = FileManager.default
    var isDirectory = ObjCBool(false)
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
      throw ArtifactReferenceError.fileNotFound(url)
    }
    guard !isDirectory.boolValue else {
      throw ArtifactReferenceError.notRegularFile(url)
    }

    let attributes: [FileAttributeKey: Any]
    do {
      attributes = try fileManager.attributesOfItem(atPath: url.path)
    } catch {
      throw ArtifactReferenceError.metadataUnavailable(url, reason: error.localizedDescription)
    }
    guard attributes[.type] as? FileAttributeType == .typeRegular else {
      throw ArtifactReferenceError.notRegularFile(url)
    }
    guard let size = attributes[.size] as? NSNumber else {
      throw ArtifactReferenceError.metadataUnavailable(url, reason: "Missing file size attribute.")
    }
    guard size.int64Value >= 0 else {
      throw ArtifactReferenceError.byteCountOverflow(url)
    }

    let initialSnapshot = FileSnapshot(
      byteCount: size.int64Value,
      modificationDate: attributes[.modificationDate] as? Date,
      fileNumber: attributes[.systemFileNumber] as? NSNumber
    )
    let digest = try digester.digest(fileAt: url, using: .sha256)
    let finalAttributes: [FileAttributeKey: Any]
    do {
      finalAttributes = try fileManager.attributesOfItem(atPath: url.path)
    } catch {
      throw ArtifactReferenceError.metadataUnavailable(url, reason: error.localizedDescription)
    }
    guard let finalSize = finalAttributes[.size] as? NSNumber,
          finalSize.int64Value >= 0 else {
      throw ArtifactReferenceError.metadataUnavailable(url, reason: "Missing final file size attribute.")
    }
    let finalSnapshot = FileSnapshot(
      byteCount: finalSize.int64Value,
      modificationDate: finalAttributes[.modificationDate] as? Date,
      fileNumber: finalAttributes[.systemFileNumber] as? NSNumber
    )
    guard initialSnapshot == finalSnapshot else {
      throw ArtifactReferenceError.changedDuringReference(url)
    }

    return ArtifactReference(
      locator: locator,
      digest: digest,
      byteCount: UInt64(finalSnapshot.byteCount),
      producer: producer
    )
  }
}
