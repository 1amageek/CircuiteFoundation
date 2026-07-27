import CircuiteFoundation
import Foundation
import Testing

@Suite
struct DesignDatabaseContractTests {
  @Test
  func fixedWidthIdentitiesUseCanonicalLowercaseHexadecimal() throws {
    let database = try DesignDatabaseID(high: 1, low: 2)
    let revision = DesignRevisionID(high: 3, low: 4)
    let entity = try DesignEntityID(rawValue: 5)

    #expect(database.description == "00000000000000010000000000000002")
    #expect(revision.description == "00000000000000030000000000000004")
    #expect(entity.description == "0000000000000005")
    #expect(try JSONDecoder().decode(DesignDatabaseID.self, from: JSONEncoder().encode(database)) == database)
    #expect(try JSONDecoder().decode(DesignEntityID.self, from: JSONEncoder().encode(entity)) == entity)
  }

  @Test
  func identitiesRejectZeroAndNonCanonicalEncoding() {
    #expect(throws: DesignIdentityError.self) {
      try DesignDatabaseID(high: 0, low: 0)
    }
    #expect(throws: DesignIdentityError.self) {
      try DesignEntityID(rawValue: 0)
    }
    #expect(throws: DesignIdentityError.self) {
      try DesignDatabaseID(hexadecimalValue: "0000000000000001000000000000000A")
    }
  }

  @Test
  func subjectCasesRemainDistinctAcrossSerialization() throws {
    let database = try DesignDatabaseID(high: 1, low: 2)
    let revision = DesignRevisionReference(
      databaseID: database,
      revisionID: DesignRevisionID(high: 3, low: 4)
    )
    let facet = try DesignFacetID(rawValue: "logic")
    let kind = try DesignEntityKindID(rawValue: "net")
    let entity = DesignSubjectReference.entity(
      DesignEntityReference(
        revision: revision,
        facetID: facet,
        kindID: kind,
        entityID: try DesignEntityID(rawValue: 5)
      )
    )
    let path = DesignSubjectReference.path(
      try DesignPathReference(
        facetID: facet,
        kindID: kind,
        localIdentifier: "clock"
      )
    )

    let encoded = try JSONEncoder().encode([entity, path])
    let decoded = try JSONDecoder().decode([DesignSubjectReference].self, from: encoded)
    #expect(decoded == [entity, path])
  }

  @Test
  func compatibilityRequiresEveryRequiredIntersection() throws {
    let range = try SchemaVersionRange(
      lowerBound: SchemaVersion(major: 1, minor: 0, patch: 0),
      upperBound: SchemaVersion(major: 2, minor: 0, patch: 0)
    )
    let facet = try DesignFacetID(rawValue: "logic")
    let schemaID = try DesignSchemaID(rawValue: "lsi.logic")
    let descriptor = try DesignSchemaDescriptor(
      schemaID: schemaID,
      facetID: facet,
      version: SchemaVersion(major: 1, minor: 2, patch: 0),
      canonicalDigest: try ContentDigest(
        algorithm: .sha256,
        hexadecimalValue: String(repeating: "a", count: 64)
      )
    )
    let requiredCapability = DesignCapabilityRequirement(
      capabilityID: try DesignCapabilityID(rawValue: "query.spatial"),
      versions: range,
      necessity: .required
    )
    let report = try DesignCompatibilityNegotiator.negotiate(
      offeredSchemas: [descriptor],
      requiredSchemas: [DesignSchemaRequirement(schemaID: schemaID, versions: range)],
      offeredCapabilities: DesignCapabilitySet([]),
      requiredCapabilities: [requiredCapability]
    )

    #expect(!report.isCompatible)
    #expect(report.missingRequiredCapabilities == [requiredCapability])
    #expect(report.agreedSchemas == [descriptor])
  }

  @Test
  func compatibilityIncludesTransitiveSchemaRequirements() throws {
    let range = try SchemaVersionRange(
      lowerBound: SchemaVersion(major: 1, minor: 0, patch: 0),
      upperBound: SchemaVersion(major: 2, minor: 0, patch: 0)
    )
    let dependencyID = try DesignSchemaID(rawValue: "lsi.technology")
    let root = try DesignSchemaDescriptor(
      schemaID: try DesignSchemaID(rawValue: "lsi.physical"),
      facetID: try DesignFacetID(rawValue: "physical"),
      version: SchemaVersion(major: 1, minor: 0, patch: 0),
      canonicalDigest: try ContentDigest(
        algorithm: .sha256,
        hexadecimalValue: String(repeating: "b", count: 64)
      ),
      requiredSchemas: [DesignSchemaRequirement(schemaID: dependencyID, versions: range)]
    )
    let report = try DesignCompatibilityNegotiator.negotiate(
      offeredSchemas: [root],
      requiredSchemas: [DesignSchemaRequirement(schemaID: root.schemaID, versions: range)],
      offeredCapabilities: DesignCapabilitySet([]),
      requiredCapabilities: []
    )

    #expect(!report.isCompatible)
    #expect(report.missingRequiredSchemas == [
      DesignSchemaRequirement(schemaID: dependencyID, versions: range)
    ])
  }

  @Test
  func provenanceCarriesScopedInputAndOutputRevisions() throws {
    let database = try DesignDatabaseID(high: 1, low: 2)
    let input = DesignRevisionReference(
      databaseID: database,
      revisionID: DesignRevisionID(high: 3, low: 4)
    )
    let output = DesignRevisionReference(
      databaseID: database,
      revisionID: DesignRevisionID(high: 5, low: 6)
    )
    let instant = Date(timeIntervalSince1970: 1)
    let provenance = try ExecutionProvenance(
      producer: ProducerIdentity(
        kind: .engine,
        identifier: "LogicEngine",
        version: "1.0.0"
      ),
      inputDesignRevision: input,
      outputDesignRevision: output,
      startedAt: instant,
      completedAt: instant
    )
    let decoded = try JSONDecoder().decode(
      ExecutionProvenance.self,
      from: JSONEncoder().encode(provenance)
    )

    #expect(decoded.inputDesignRevision == input)
    #expect(decoded.outputDesignRevision == output)
  }
}
