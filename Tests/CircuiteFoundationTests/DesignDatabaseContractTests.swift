import CircuiteFoundation
import CircuiteFoundationFoundation
import Foundation
import Testing

@Suite
struct DesignDatabaseContractTests {
  @Test
  func fixedWidthIdentitiesUseCanonicalLowercaseHexadecimal() throws {
    let database = try DesignDatabaseID(high: 1, low: 2)
    let revision = DesignRevisionID(high: 3, low: 4)
    let entity = try DesignEntityID(rawValue: 5)
    let occurrence = try DesignRelationOccurrenceID(rawValue: 6)

    #expect(database.description == "00000000000000010000000000000002")
    #expect(revision.description == "00000000000000030000000000000004")
    #expect(entity.description == "0000000000000005")
    #expect(occurrence.description == "0000000000000006")
    #expect(try JSONDecoder().decode(DesignDatabaseID.self, from: JSONEncoder().encode(database)) == database)
    #expect(try JSONDecoder().decode(DesignEntityID.self, from: JSONEncoder().encode(entity)) == entity)
    #expect(
      try JSONDecoder().decode(
        DesignRelationOccurrenceID.self,
        from: JSONEncoder().encode(occurrence)
      ) == occurrence
    )
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
      try DesignRelationOccurrenceID(rawValue: 0)
    }
    #expect(throws: DesignIdentityError.self) {
      try DesignDatabaseID(hexadecimalValue: "0000000000000001000000000000000A")
    }
  }

  @Test
  func authorizationSubjectScopeUsesCanonicalNonzeroOpaqueIdentity() throws {
    let scope = try DesignAuthorizationSubjectScopeID(high: 1, low: 2)
    let encoded = try JSONEncoder().encode(scope)

    #expect(scope.description == "00000000000000010000000000000002")
    #expect(
      try JSONDecoder().decode(
        DesignAuthorizationSubjectScopeID.self,
        from: encoded
      ) == scope
    )

    for invalid in [
      "00000000000000000000000000000000",
      "0000000000000001000000000000000A",
      "0000000000000001000000000000000g",
      "0000000000000001000000000000000",
    ] {
      #expect(throws: DesignIdentityError.self) {
        try DesignAuthorizationSubjectScopeID(hexadecimalValue: invalid)
      }
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
  func compatibilityErrorsPreserveTypedPayloadsAcrossSerialization() throws {
    let errors: [SchemaCompatibilityError] = [
      .invalidVersionRange(
        lowerBound: SchemaVersion(major: 2, minor: 0, patch: 0),
        upperBound: SchemaVersion(major: 1, minor: 0, patch: 0)
      ),
      .duplicateSchema(try DesignSchemaID(rawValue: "lsi.logic")),
      .duplicateCapability(
        try DesignCapabilityID(rawValue: "query.spatial")
      ),
    ]

    let encoded = try JSONEncoder().encode(errors)
    #expect(
      try JSONDecoder().decode(
        [SchemaCompatibilityError].self,
        from: encoded
      ) == errors
    )
  }

  @Test
  func canonicalCompatibilityCollectionsRejectDuplicateIdentifiers() throws {
    let versions = try SchemaVersionRange(
      lowerBound: SchemaVersion(major: 1, minor: 0, patch: 0),
      upperBound: SchemaVersion(major: 2, minor: 0, patch: 0)
    )
    let capabilityID = try DesignCapabilityID(rawValue: "query.exact")
    let capability = DesignCapabilityDescriptor(
      capabilityID: capabilityID,
      versions: versions
    )
    #expect(
      throws: SchemaCompatibilityError.duplicateCapability(capabilityID)
    ) {
      _ = try DesignCapabilitySet([capability, capability])
    }

    let schemaID = try DesignSchemaID(rawValue: "lsi.logic")
    let requirement = DesignSchemaRequirement(
      schemaID: schemaID,
      versions: versions
    )
    let descriptor = try DesignSchemaDescriptor(
      schemaID: schemaID,
      facetID: DesignFacetID(rawValue: "logic"),
      version: SchemaVersion(major: 1, minor: 0, patch: 0),
      canonicalDigest: ContentDigest(
        algorithm: .sha256,
        hexadecimalValue: String(repeating: "a", count: 64)
      )
    )
    #expect(throws: SchemaCompatibilityError.duplicateSchema(schemaID)) {
      _ = try DesignSchemaDescriptor(
        schemaID: try DesignSchemaID(rawValue: "lsi.consumer"),
        facetID: DesignFacetID(rawValue: "consumer"),
        version: SchemaVersion(major: 1, minor: 0, patch: 0),
        canonicalDigest: ContentDigest(
          algorithm: .sha256,
          hexadecimalValue: String(repeating: "b", count: 64)
        ),
        requiredSchemas: [requirement, requirement]
      )
    }
    #expect(throws: SchemaCompatibilityError.duplicateSchema(schemaID)) {
      _ = try DesignCompatibilityNegotiator.negotiate(
        offeredSchemas: [descriptor, descriptor],
        requiredSchemas: [requirement],
        offeredCapabilities: try DesignCapabilitySet([capability]),
        requiredCapabilities: []
      )
    }
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
