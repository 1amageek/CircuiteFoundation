public struct ArtifactAccessBudget: Sendable, Hashable {
  public let maximumPageByteCount: UInt64
  public let maximumTotalByteCount: UInt64
  public let maximumPageCount: UInt64
  public let maximumWorkUnitCount: UInt64
  public let maximumDurationNanoseconds: UInt64

  public init(
    maximumPageByteCount: UInt64,
    maximumTotalByteCount: UInt64,
    maximumPageCount: UInt64,
    maximumWorkUnitCount: UInt64,
    maximumDurationNanoseconds: UInt64
  ) throws {
    guard maximumPageByteCount > 0 else {
      throw ArtifactAccessBudgetError.zeroMaximumPageByteCount
    }
    guard maximumTotalByteCount > 0 else {
      throw ArtifactAccessBudgetError.zeroMaximumTotalByteCount
    }
    guard maximumPageCount > 0 else {
      throw ArtifactAccessBudgetError.zeroMaximumPageCount
    }
    guard maximumWorkUnitCount > 0 else {
      throw ArtifactAccessBudgetError.zeroMaximumWorkUnitCount
    }
    guard maximumDurationNanoseconds > 0 else {
      throw ArtifactAccessBudgetError.zeroMaximumDurationNanoseconds
    }
    guard maximumPageByteCount <= maximumTotalByteCount else {
      throw ArtifactAccessBudgetError.pageLimitExceedsTotal(
        page: maximumPageByteCount,
        total: maximumTotalByteCount
      )
    }
    self.maximumPageByteCount = maximumPageByteCount
    self.maximumTotalByteCount = maximumTotalByteCount
    self.maximumPageCount = maximumPageCount
    self.maximumWorkUnitCount = maximumWorkUnitCount
    self.maximumDurationNanoseconds = maximumDurationNanoseconds
  }

}
