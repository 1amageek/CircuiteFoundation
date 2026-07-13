/// Stable projections used by domain packages when rendering artifact
/// diagnostics. These properties do not create a second artifact contract;
/// the locator and digest remain the canonical representation.
public extension ArtifactReference {
  var path: String { locator.path }
  var kind: ArtifactKind { locator.kind }
  var format: ArtifactFormat { locator.format }
  var artifactID: String { id.rawValue }
  var sha256: String { digest.hexadecimalValue }
}
