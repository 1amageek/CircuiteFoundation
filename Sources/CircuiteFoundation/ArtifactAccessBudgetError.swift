public enum ArtifactAccessBudgetError: Error, Sendable, Equatable {
  case zeroMaximumPageByteCount
  case zeroMaximumTotalByteCount
  case zeroMaximumPageCount
  case zeroMaximumWorkUnitCount
  case zeroMaximumDurationNanoseconds
  case pageLimitExceedsTotal(page: UInt64, total: UInt64)
}
