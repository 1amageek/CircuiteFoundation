/// Stable semantic projections used by domain packages when rendering artifact diagnostics.
public extension ArtifactReference {
  var kind: ArtifactKind { descriptor.kind }
  var format: ArtifactFormat { descriptor.format }
  var artifactID: String { id.description }
}
