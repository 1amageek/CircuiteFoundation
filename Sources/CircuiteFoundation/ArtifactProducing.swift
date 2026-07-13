public protocol ArtifactProducing: Sendable {
  var artifacts: [ArtifactReference] { get }
}
