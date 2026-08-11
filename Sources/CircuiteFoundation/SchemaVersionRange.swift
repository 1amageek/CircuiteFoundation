public struct SchemaVersionRange: Sendable, Hashable {
  public let lowerBound: SchemaVersion
  public let upperBound: SchemaVersion

  public init(
    lowerBound: SchemaVersion,
    upperBound: SchemaVersion
  ) throws(SchemaCompatibilityError) {
    guard lowerBound < upperBound else {
      throw SchemaCompatibilityError.invalidVersionRange(
        lowerBound: lowerBound,
        upperBound: upperBound
      )
    }
    self.lowerBound = lowerBound
    self.upperBound = upperBound
  }

  public func contains(_ version: SchemaVersion) -> Bool {
    version >= lowerBound && version < upperBound
  }

  public func intersection(with other: Self) -> Self? {
    let lower = max(lowerBound, other.lowerBound)
    let upper = min(upperBound, other.upperBound)
    guard lower < upper else { return nil }
    return Self(lowerBoundUnchecked: lower, upperBound: upper)
  }

  private init(lowerBoundUnchecked: SchemaVersion, upperBound: SchemaVersion) {
    self.lowerBound = lowerBoundUnchecked
    self.upperBound = upperBound
  }
}
