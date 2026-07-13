import Foundation

public struct LocalArtifactReferencer: ArtifactReferencing {
  private let digester: any ContentDigesting

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

    let digest = try digester.digest(fileAt: url, using: .sha256)
    return ArtifactReference(
      locator: locator,
      digest: digest,
      byteCount: size.uint64Value,
      producer: producer
    )
  }
}
