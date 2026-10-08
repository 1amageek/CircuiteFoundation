public protocol ArtifactSourceControl: Sendable {
  func check() throws(ArtifactSourceControlError)
  func charge(_ work: ArtifactSourceWork) throws(ArtifactSourceControlError)
  func retain(_ extent: ArtifactSourceExtent)
    throws(ArtifactSourceControlError) -> any ArtifactSourceRetention
}
