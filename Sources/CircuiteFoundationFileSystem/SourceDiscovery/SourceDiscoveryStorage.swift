/// Immutable shared storage binds managed extents to the last source or inventory copy.
final class SourceDiscoveryStorage<Element: Sendable>: Sendable {
  let elements: [Element]
  let retentions: [any ArtifactSourceRetention]

  init(elements: [Element], retentions: [any ArtifactSourceRetention]) {
    self.elements = elements
    self.retentions = retentions
  }
}
