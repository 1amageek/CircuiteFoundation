extension ContentDigest {
  /// Constructs the same checked value using the caller's retained accounting
  /// owner. Keep that owner alive while using invocation-managed value copies.
  public init(algorithm: ContentDigestAlgorithm, hexadecimalValue: String,
              control: any ContentDigestConstructionControl) throws {
    try control.check()
    // Swift 6.4's special scalar case-mapping length is stored in UInt8.
    let scratchBytes = try Self.constructionSum(UInt64(UInt8.max), UInt64(MemoryLayout<String>.stride))
    let planning = ConstructionLease(owner: try control.reserveTemporary(byteCount: scratchBytes))
    defer { withExtendedLifetime(planning) {} }
    try control.check()

    var inputBytes: UInt64 = 0
    var mappedBytes: UInt64 = 0
    var scalarVisits: UInt64 = 0
    var validationVisits: UInt64 = 0
    var validPrefix = true
    for scalar in hexadecimalValue.unicodeScalars {
      try control.charge(workUnits: 1)
      try control.check()
      let mapping = scalar.properties.lowercaseMapping
      let mappedCount = mapping.utf8.count
      guard mappedCount <= Int(UInt8.max) else { throw ContentDigestError.byteCountOverflow }
      inputBytes = try Self.constructionSum(inputBytes, UInt64(scalar.utf8.count))
      mappedBytes = try Self.constructionSum(mappedBytes, UInt64(mappedCount))
      scalarVisits = try Self.constructionSum(scalarVisits, 1)
      if validPrefix {
        for byte in mapping.utf8 {
          try control.charge(workUnits: 1)
          try control.check()
          validationVisits = try Self.constructionSum(validationVisits, 1)
          if !((byte >= 48 && byte <= 57) || (byte >= 65 && byte <= 70)
               || (byte >= 97 && byte <= 102)) {
            validPrefix = false
            break
          }
        }
      }
    }

    // The original conversion starts with input-sized capacity; replacement
    // mapped backing can coexist. The input String remains separately caller-owned.
    let conversion: ConstructionLease?
    if inputBytes > 0 {
      conversion = ConstructionLease(owner: try control.reserveTemporary(byteCount: inputBytes))
      try control.check()
    } else { conversion = nil }
    defer { withExtendedLifetime(conversion) {} }
    if mappedBytes > 0 {
      try control.reserveRetained(byteCount: mappedBytes)
      try control.check()
    }
    let executionWork = try Self.constructionSum(scalarVisits, validationVisits)
    if executionWork > 0 {
      try control.charge(workUnits: executionWork)
      try control.check()
    }
    // Preserve the original Unicode conversion, validation order and typed cause.
    try self.init(algorithm: algorithm, hexadecimalValue: hexadecimalValue)
    try control.check()
    guard UInt64(self.hexadecimalValue.utf8.count) == mappedBytes else {
      throw ContentDigestError.byteCountOverflow
    }
  }

  private struct ConstructionLease: Sendable {
    let owner: any Sendable
  }

  private static func constructionSum(_ first: UInt64, _ second: UInt64)
    throws(ContentDigestError) -> UInt64 {
    let result = first.addingReportingOverflow(second)
    guard !result.overflow, result.partialValue <= UInt64(Int.max) else { throw .byteCountOverflow }
    return result.partialValue
  }
}
