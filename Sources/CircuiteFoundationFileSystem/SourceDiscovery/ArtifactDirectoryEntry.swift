import CircuiteFoundation

public struct ArtifactDirectoryEntry: Sendable, Hashable {
  public enum Kind: Sendable, Hashable { case regularFile, directory, symbolicLink, other }
  public let relativePath: ArtifactRelativePath
  public let kind: Kind
  private let retentions: [any ArtifactSourceRetention]

  init(relativePath: ArtifactRelativePath, kind: Kind,
       retentions: [any ArtifactSourceRetention] = []) {
    self.relativePath = relativePath
    self.kind = kind
    self.retentions = retentions
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.relativePath == rhs.relativePath && lhs.kind == rhs.kind
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(relativePath)
    hasher.combine(kind)
  }
}
