import Foundation

public struct LocalArtifactVerifier: ArtifactVerifying {
  private let digester: any ContentDigesting

  public init(digester: any ContentDigesting = SHA256ContentDigester()) {
    self.digester = digester
  }

  public func verify(
    _ reference: ArtifactReference,
    relativeTo workspaceRoot: URL? = nil
  ) -> ArtifactIntegrity {
    let fileManager = FileManager.default
    let url: URL
    do {
      url = try reference.locator.location.resolvedFileURL(relativeTo: workspaceRoot)
    } catch {
      return ArtifactIntegrity(issues: [.invalidLocation(error.localizedDescription)])
    }

    var isDirectory = ObjCBool(false)
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
      return ArtifactIntegrity(issues: [.missingFile(url.path)])
    }
    guard !isDirectory.boolValue else {
      return ArtifactIntegrity(issues: [.notRegularFile(url.path)])
    }

    var issues: [ArtifactIntegrityIssue] = []
    do {
      let attributes = try fileManager.attributesOfItem(atPath: url.path)
      if attributes[.type] as? FileAttributeType != .typeRegular {
        issues.append(.notRegularFile(url.path))
        return ArtifactIntegrity(issues: issues)
      } else if let size = attributes[.size] as? NSNumber {
        let actualByteCount = size.uint64Value
        if actualByteCount != reference.byteCount {
          issues.append(
            .byteCountMismatch(expected: reference.byteCount, actual: actualByteCount)
          )
        }
      } else {
        issues.append(.unreadableFile("Missing file size attribute for \(url.path)"))
      }
    } catch {
      issues.append(.unreadableFile(error.localizedDescription))
    }

    do {
      let actualDigest = try digester.digest(fileAt: url, using: reference.digest.algorithm)
      if actualDigest != reference.digest {
        issues.append(.digestMismatch(expected: reference.digest, actual: actualDigest))
      }
    } catch ContentDigestError.unsupportedAlgorithm(let algorithm) {
      issues.append(.unsupportedDigestAlgorithm(algorithm))
    } catch {
      issues.append(.unreadableFile(error.localizedDescription))
    }

    return ArtifactIntegrity(issues: issues)
  }
}
