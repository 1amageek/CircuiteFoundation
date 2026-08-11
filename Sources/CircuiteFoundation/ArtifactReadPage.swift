public struct ArtifactReadPage: Sendable {
  public let offset: UInt64
  public let bytes: any ArtifactOwnedBytes
  public let cumulativeByteCount: UInt64
  public let cumulativeWork: ArtifactAccessWorkReport
  public let completion: ArtifactReadCompletion
  public let finalReceipt: ArtifactAccessReceipt?

  public init(
    offset: UInt64,
    bytes: any ArtifactOwnedBytes,
    cumulativeByteCount: UInt64,
    cumulativeWork: ArtifactAccessWorkReport,
    completion: ArtifactReadCompletion,
    finalReceipt: ArtifactAccessReceipt?
  ) throws {
    switch (completion, finalReceipt) {
    case (.more, .some):
      throw ArtifactReadPageError.receiptBeforeCompletion
    case (.complete, .none):
      throw ArtifactReadPageError.missingReceiptAtCompletion
    case (.more, .none), (.complete, .some):
      break
    }
    let (pageEnd, overflow) = offset.addingReportingOverflow(bytes.byteCount)
    guard !overflow else {
      throw ArtifactReadPageError.offsetOverflow
    }
    guard cumulativeByteCount >= pageEnd else {
      throw ArtifactReadPageError.cumulativeByteCountPrecedesPageEnd(
        cumulative: cumulativeByteCount,
        pageEnd: pageEnd
      )
    }
    self.offset = offset
    self.bytes = bytes
    self.cumulativeByteCount = cumulativeByteCount
    self.cumulativeWork = cumulativeWork
    self.completion = completion
    self.finalReceipt = finalReceipt
  }
}
