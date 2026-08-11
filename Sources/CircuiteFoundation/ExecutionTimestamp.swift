public struct ExecutionTimestamp: Sendable, Hashable, Comparable {
  public let secondsSinceUnixEpoch: Double

  public init(secondsSinceUnixEpoch: Double) throws(ExecutionProvenanceError) {
    guard secondsSinceUnixEpoch.isFinite else {
      throw .nonFiniteTimestamp(kind: "Execution", value: secondsSinceUnixEpoch)
    }
    self.secondsSinceUnixEpoch = secondsSinceUnixEpoch
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.secondsSinceUnixEpoch < rhs.secondsSinceUnixEpoch
  }

}
