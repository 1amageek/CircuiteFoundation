public struct DesignObjectReference: Sendable, Hashable, Codable {
  public let kind: DesignObjectKind
  public let identifier: String
  public let hierarchy: HierarchyPath

  public init(
    kind: DesignObjectKind,
    identifier: String,
    hierarchy: HierarchyPath = .root
  ) {
    self.kind = kind
    self.identifier = identifier
    self.hierarchy = hierarchy
  }
}
