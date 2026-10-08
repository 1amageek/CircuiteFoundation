import CircuiteFoundation

public struct ArtifactDirectoryEntry: Sendable, Hashable {
  public enum Kind: Sendable, Hashable { case regularFile, directory, symbolicLink, other }
  public let relativePath: ArtifactRelativePath
  public let kind: Kind

  init(relativePath: ArtifactRelativePath, kind: Kind) {
    self.relativePath = relativePath
    self.kind = kind
  }
}
