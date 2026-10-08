public enum ArtifactSourceResource: Sendable, Hashable {
  case readBytes, hashedBytes, pages, workUnits, visitedEntries
  case ownedBytes, temporaryBytes, openResources
}
