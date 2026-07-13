public protocol EvidenceProviding: Sendable {
  var evidence: EvidenceManifest { get }
}
