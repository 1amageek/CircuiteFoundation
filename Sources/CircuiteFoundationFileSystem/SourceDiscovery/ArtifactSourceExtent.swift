/// Managed payload/container capacity, separate from cumulative work and allocator overhead.
public enum ArtifactSourceExtent: Sendable, Hashable {
  case ownedBytes(UInt64)
  case temporaryBytes(UInt64)
  case openResources(UInt64)
}
