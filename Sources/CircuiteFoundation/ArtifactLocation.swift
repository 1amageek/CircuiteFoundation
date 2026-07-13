import Foundation

public struct ArtifactLocation: Sendable, Hashable, Codable {
  public enum Storage: String, Sendable, Hashable, Codable {
    case workspaceRelative
    case absoluteFileURL
  }

  public let storage: Storage
  public let value: String

  public init(workspaceRelativePath path: String) throws {
    try Self.validateWorkspaceRelativePath(path)
    storage = .workspaceRelative
    value = path
  }

  public init(fileURL: URL) throws {
    guard fileURL.isFileURL else {
      throw ArtifactLocationError.nonFileURL(fileURL)
    }
    guard fileURL.path.hasPrefix("/") else {
      throw ArtifactLocationError.nonAbsoluteFileURL(fileURL)
    }
    storage = .absoluteFileURL
    value = fileURL.standardizedFileURL.absoluteString
  }

  public func resolvedFileURL(relativeTo workspaceRoot: URL? = nil) throws -> URL {
    switch storage {
    case .absoluteFileURL:
      guard let url = URL(string: value), url.isFileURL else {
        throw ArtifactLocationError.invalidWorkspaceRelativePath(value)
      }
      return url.standardizedFileURL
    case .workspaceRelative:
      guard let workspaceRoot else {
        throw ArtifactLocationError.missingWorkspaceRoot
      }
      guard workspaceRoot.isFileURL, workspaceRoot.path.hasPrefix("/") else {
        throw ArtifactLocationError.workspaceRootIsNotAbsolute(workspaceRoot)
      }

      let canonicalRoot = workspaceRoot.standardizedFileURL.resolvingSymlinksInPath()
      let candidate =
        canonicalRoot
        .appendingPathComponent(value, isDirectory: false)
        .standardizedFileURL
        .resolvingSymlinksInPath()
      let rootPath =
        canonicalRoot.path.hasSuffix("/")
        ? canonicalRoot.path
        : canonicalRoot.path + "/"

      guard candidate.path == canonicalRoot.path || candidate.path.hasPrefix(rootPath) else {
        throw ArtifactLocationError.outsideWorkspaceRoot(candidate)
      }
      return candidate
    }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let storage = try container.decode(Storage.self, forKey: .storage)
    let value = try container.decode(String.self, forKey: .value)

    switch storage {
    case .workspaceRelative:
      try self.init(workspaceRelativePath: value)
    case .absoluteFileURL:
      guard let url = URL(string: value) else {
        throw DecodingError.dataCorruptedError(
          forKey: .value,
          in: container,
          debugDescription: "Artifact location contains an invalid URL."
        )
      }
      try self.init(fileURL: url)
    }
  }

  private enum CodingKeys: String, CodingKey {
    case storage
    case value
  }

  private static func validateWorkspaceRelativePath(_ path: String) throws {
    let components = path.split(separator: "/", omittingEmptySubsequences: false)
    let hasControlCharacter = path.unicodeScalars.contains {
      CharacterSet.controlCharacters.contains($0)
    }
    let isInvalid =
      path.isEmpty
      || path.hasPrefix("/")
      || path.hasPrefix("~")
      || path.contains("\\")
      || hasControlCharacter
      || components.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." })

    guard !isInvalid else {
      throw ArtifactLocationError.invalidWorkspaceRelativePath(path)
    }
  }
}
