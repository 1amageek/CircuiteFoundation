public enum ArtifactReadPageError: Error, Sendable, Equatable {
  case receiptBeforeCompletion
  case missingReceiptAtCompletion
  case ownerByteCountMismatch(declared: UInt64, actual: UInt64)
  case cumulativeByteCountPrecedesPageEnd(cumulative: UInt64, pageEnd: UInt64)
  case offsetOverflow
}
