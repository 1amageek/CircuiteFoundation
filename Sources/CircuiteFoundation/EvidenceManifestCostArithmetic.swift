/// Checked scalar sizing shared only by the evidence/ArtifactID cost owners.
internal enum EvidenceManifestCostArithmetic {
  static func add(_ a: UInt64, _ b: UInt64) throws(ContentDigestError) -> UInt64 {
    let (value, overflow) = a.addingReportingOverflow(b)
    guard !overflow else { throw .byteCountOverflow }
    return value
  }
  static func multiply(_ a: UInt64, _ b: UInt64) throws(ContentDigestError) -> UInt64 {
    let (value, overflow) = a.multipliedReportingOverflow(by: b)
    guard !overflow else { throw .byteCountOverflow }
    return value
  }
  static func utf8Count(_ value: String, checkpoint: (UInt64) throws -> Void) throws -> UInt64 {
    try checkpoint(1)
    var iterator = value.utf8.makeIterator()
    var count: UInt64 = 0
    while true {
      try checkpoint(1)
      guard iterator.next() != nil else { return count }
      count = try add(count, 1)
    }
  }
}
