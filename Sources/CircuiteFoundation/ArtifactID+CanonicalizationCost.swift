extension ArtifactID {
  /// Owns sizing of the existing v1 encoding; never constructs canonicalBytes.
  internal func evidenceCanonicalizationCost(checkpoint: (UInt64) throws -> Void) throws
    -> (byteCount: UInt64, temporaryByteCount: UInt64, workUnits: UInt64) {
    typealias A = EvidenceManifestCostArithmetic
    try checkpoint(1)
    let algorithm = try A.utf8Count(digest.algorithm.rawValue, checkpoint: checkpoint)
    let hexadecimal = try A.utf8Count(digest.hexadecimalValue, checkpoint: checkpoint)
    let decoded = hexadecimal / 2
    // Domain/NUL, version, two UInt16 lengths, then the UInt64 payload count.
    let domain = UInt64("CircuiteArtifactContent".utf8.count)
    let fixed = domain + 15
    let bytes = try A.add(A.add(fixed, algorithm), decoded)
    let arrayHeaders = UInt64(MemoryLayout<[UInt8]>.stride * 5)
    // The growing output may coexist with its replaced storage. Other arrays
    // have known collection/reserve counts; all endian words sum to 14 bytes.
    let copies = try A.add(A.add(algorithm, hexadecimal), A.add(decoded, 14))
    let temporary = try A.add(A.add(A.multiply(bytes, 4), copies), arrayHeaders)
    let work = try A.add(A.add(bytes, copies), decoded)
    return (bytes, temporary, work)
  }
}
