import CircuiteFoundationFoundation
import Foundation
import Testing

@Suite
struct SerializationAdapterTests {
  @Test
  func interoperabilityBackendUsesExplicitTaggedEncoding() throws {
    let backend = InteroperabilityBackend.external(.openROAD)
    let data = try sortedJSONEncoder().encode(backend)

    #expect(
      String(decoding: data, as: UTF8.self)
        == #"{"externalSystem":"open-road","kind":"external"}"#
    )
    #expect(try JSONDecoder().decode(InteroperabilityBackend.self, from: data) == backend)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(
        InteroperabilityBackend.self,
        from: Data(#"{"kind":"unknown"}"#.utf8)
      )
    }
  }

  @Test
  func capabilitySetAdapterPreservesCanonicalOrdering() throws {
    let first = DesignCapabilityDescriptor(
      capabilityID: try DesignCapabilityID(rawValue: "capability.a"),
      versions: try SchemaVersionRange(
        lowerBound: .v1,
        upperBound: .v2
      )
    )
    let second = DesignCapabilityDescriptor(
      capabilityID: try DesignCapabilityID(rawValue: "capability.b"),
      versions: try SchemaVersionRange(
        lowerBound: .v1,
        upperBound: .v2
      )
    )
    let expected = try DesignCapabilitySet([second, first])
    let data = try JSONEncoder().encode(expected)
    let decoded = try JSONDecoder().decode(DesignCapabilitySet.self, from: data)

    #expect(expected.descriptors == [first, second])
    #expect(decoded == expected)
  }

  @Test
  func artifactIntegrityIssueAdapterRejectsPayloadCodeMismatch() throws {
    let issue = ArtifactIntegrityIssue.byteCountMismatch(expected: 5, actual: 4)
    let data = try sortedJSONEncoder().encode(issue)

    #expect(try JSONDecoder().decode(ArtifactIntegrityIssue.self, from: data) == issue)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(
        ArtifactIntegrityIssue.self,
        from: Data(#"{"code":"byteCountMismatch","detail":"wrong payload"}"#.utf8)
      )
    }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(
        ArtifactIntegrityIssue.self,
        from: Data(#"{"code":"unknown"}"#.utf8)
      )
    }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(
        ArtifactIntegrityIssue.self,
        from: Data(#"{"code":"invalidLocation","detail":"invalid","expectedByteCount":5}"#.utf8)
      )
    }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(
        ArtifactIntegrityIssue.self,
        from: Data(#"{"code":"byteCountMismatch","expectedByteCount":5}"#.utf8)
      )
    }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(
        ArtifactIntegrityIssue.self,
        from: Data(
          #"{"code":"digestMismatch","expectedDigest":{"algorithm":"sha256","hexadecimalValue":"00"}}"#.utf8
        )
      )
    }
  }

  private func sortedJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return encoder
  }
}
