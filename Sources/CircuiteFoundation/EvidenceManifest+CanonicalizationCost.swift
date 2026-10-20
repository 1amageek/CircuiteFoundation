public extension EvidenceManifest {
  /// Plans the existing factory's managed scratch without materializing its encoding.
  /// Checkpoint charges planning traversal BEFORE access; returned workUnits covers
  /// subsequent construction only. Backend allocation and caller input owners are separate.
  static func canonicalizationCost(
    schemaVersion: SchemaVersion = Self.currentSchemaVersion,
    provenance: ExecutionProvenance,
    artifacts: [ArtifactReference],
    checkpoint: (UInt64) throws -> Void
  ) throws -> (canonicalByteCount: UInt64, temporaryByteCount: UInt64, retainedByteCount: UInt64, workUnits: UInt64) {
    try checkpoint(1)
    var cost = EvidenceManifestCostCounter()
    try cost.string("CircuiteEvidenceManifest", checkpoint: checkpoint)
    try cost.schema(schemaVersion, checkpoint: checkpoint)
    try cost.producer(provenance.producer, checkpoint: checkpoint)
    try cost.word()
    for index in provenance.supportingTools.indices {
      try checkpoint(1)
      try cost.producer(provenance.supportingTools[index], checkpoint: checkpoint)
    }
    try cost.artifacts(provenance.inputs, checkpoint: checkpoint)
    try cost.invocation(provenance.invocation, checkpoint: checkpoint)
    try cost.environment(provenance.environment, checkpoint: checkpoint)
    try cost.digest(provenance.configurationDigest, checkpoint: checkpoint)
    try cost.revision(provenance.inputDesignRevision, checkpoint: checkpoint)
    try cost.revision(provenance.outputDesignRevision, checkpoint: checkpoint)
    try checkpoint(1)
    try cost.presence()
    if provenance.randomSeed != nil { try cost.word() }
    try cost.word(); try cost.word()
    try cost.artifacts(artifacts, checkpoint: checkpoint)
    return try cost.result()
  }
}

private struct EvidenceManifestCostCounter {
  typealias A = EvidenceManifestCostArithmetic
  var bytes: UInt64 = 0
  var extraWork: UInt64 = 0
  var largestScratch: UInt64 = 0
  mutating func word() throws(ContentDigestError) { bytes = try A.add(bytes, 8) }
  mutating func presence() throws(ContentDigestError) { bytes = try A.add(bytes, 1) }
  mutating func textBytes(_ count: UInt64, generatedScratch: UInt64 = 0) throws(ContentDigestError) {
    try word(); bytes = try A.add(bytes, count)
    extraWork = try A.add(extraWork, count)
    let temporary = try A.add(A.add(count, UInt64(MemoryLayout<[UInt8]>.stride)), generatedScratch)
    largestScratch = max(largestScratch, temporary)
  }
  mutating func string(_ value: String, checkpoint: (UInt64) throws -> Void) throws {
    try textBytes(A.utf8Count(value, checkpoint: checkpoint))
  }
  mutating func optional(_ value: String?, checkpoint: (UInt64) throws -> Void) throws {
    try checkpoint(1); try presence()
    if let value { try string(value, checkpoint: checkpoint) }
  }
  mutating func schema(_ version: SchemaVersion, checkpoint: (UInt64) throws -> Void) throws {
    try checkpoint(1)
    func digits(_ input: UInt16) throws -> UInt64 {
      var value = input, count: UInt64 = 1
      while true {
        try checkpoint(1)
        guard value >= 10 else { return count }
        value /= 10; count += 1
      }
    }
    let count = try A.add(A.add(digits(version.major), digits(version.minor)), A.add(digits(version.patch), 2))
    try textBytes(count, generatedScratch: count)
    extraWork = try A.add(extraWork, count)
  }
  mutating func producer(_ value: ProducerIdentity, checkpoint: (UInt64) throws -> Void) throws {
    try checkpoint(1)
    try string(value.kind.rawValue, checkpoint: checkpoint)
    try string(value.identifier, checkpoint: checkpoint)
    try string(value.version, checkpoint: checkpoint)
    try optional(value.build, checkpoint: checkpoint)
  }
  mutating func digest(_ value: ContentDigest?, checkpoint: (UInt64) throws -> Void) throws {
    try checkpoint(1); try presence()
    if let value {
      try string(value.algorithm.rawValue, checkpoint: checkpoint)
      try string(value.hexadecimalValue, checkpoint: checkpoint)
    }
  }
  mutating func revision(_ value: DesignRevisionReference?, checkpoint: (UInt64) throws -> Void) throws {
    try checkpoint(1); try presence()
    if value != nil {
      // Each fixed ID builds two 16-byte arrays, two 16-byte digit tables,
      // two 16-byte Strings and a 32-byte concatenation. Summing those named
      // lifetimes is conservative; no String formatting buffer is constructed here.
      let descriptions: UInt64 = 128 + UInt64(MemoryLayout<[UInt8]>.stride * 4 + MemoryLayout<String>.stride * 3)
      try textBytes(32, generatedScratch: descriptions)
      try textBytes(32, generatedScratch: descriptions)
      extraWork = try A.add(extraWork, 320)
    }
  }
  mutating func invocation(_ value: ExecutionInvocation?, checkpoint: (UInt64) throws -> Void) throws {
    try checkpoint(1); try presence()
    if let value {
      try string(value.mode.rawValue, checkpoint: checkpoint)
      try optional(value.entryPoint, checkpoint: checkpoint)
      try optional(value.executable, checkpoint: checkpoint)
      try word()
      for index in value.arguments.indices {
        try checkpoint(1)
        try string(value.arguments[index], checkpoint: checkpoint)
      }
      try optional(value.workingDirectory, checkpoint: checkpoint)
    }
  }
  mutating func environment(_ value: ExecutionEnvironmentFingerprint?, checkpoint: (UInt64) throws -> Void) throws {
    try checkpoint(1); try presence()
    if let value {
      try string(value.platform, checkpoint: checkpoint)
      try string(value.architecture, checkpoint: checkpoint)
      try string(value.toolchain, checkpoint: checkpoint)
      try digest(value.environmentDigest, checkpoint: checkpoint)
    }
  }
  mutating func artifacts(_ values: [ArtifactReference], checkpoint: (UInt64) throws -> Void) throws {
    try checkpoint(1); try word()
    for index in values.indices {
      try checkpoint(1)
      let value = values[index]
      let id = try value.id.evidenceCanonicalizationCost(checkpoint: checkpoint)
      bytes = try A.add(bytes, id.byteCount)
      largestScratch = max(largestScratch, id.temporaryByteCount)
      extraWork = try A.add(extraWork, id.workUnits)
      try string(value.descriptor.role.rawValue, checkpoint: checkpoint)
      try string(value.descriptor.kind.rawValue, checkpoint: checkpoint)
      try string(value.descriptor.format.rawValue, checkpoint: checkpoint)
    }
  }
  func result() throws(ContentDigestError)
    -> (canonicalByteCount: UInt64, temporaryByteCount: UInt64, retainedByteCount: UInt64, workUnits: UInt64) {
    guard bytes <= UInt64(Int.max) else { throw .byteCountOverflow }
    // Backend-returned digest64 is NOT charged here. Only this factory's
    // additional UTF8 copy64 and decoded32 (+ two array value slots) are scratch.
    let digestScratch: UInt64 = 64 + 32 + UInt64(MemoryLayout<[UInt8]>.stride * 2)
    let writer = try A.add(A.multiply(bytes, 4), UInt64(MemoryLayout<[UInt8]>.stride))
    let temporary = try A.add(writer, max(largestScratch, digestScratch))
    let work = try A.add(A.add(bytes, extraWork), 64 + 32 + 32 + 16)
    return (bytes, temporary, 0, work)
  }
}
