import CircuiteFoundation

public enum CircuiteFoundationPortabilityProbeOutput {
  public static func make() throws -> String {
    let databaseID = try DesignDatabaseID(high: 1, low: 2)
    let subjectScopeID = try DesignAuthorizationSubjectScopeID(high: 3, low: 4)
    let revision = DesignRevisionReference(
      databaseID: databaseID,
      revisionID: DesignRevisionID(high: 5, low: 6)
    )
    let capability = DesignCapabilityDescriptor(
      capabilityID: try DesignCapabilityID(rawValue: "query.exact-revision"),
      versions: try SchemaVersionRange(
        lowerBound: SchemaVersion(major: 1, minor: 0, patch: 0),
        upperBound: SchemaVersion(major: 2, minor: 0, patch: 0)
      )
    )
    let capabilities = try DesignCapabilitySet([capability])
    let schemaID = try DesignSchemaID(rawValue: "lsi.portability")
    let schema = try DesignSchemaDescriptor(
      schemaID: schemaID,
      facetID: DesignFacetID(rawValue: "portability"),
      version: SchemaVersion(major: 1, minor: 0, patch: 0),
      canonicalDigest: ContentDigest(
        algorithm: .sha256,
        hexadecimalValue: String(repeating: "a", count: 64)
      )
    )
    let report = try DesignCompatibilityNegotiator.negotiate(
      offeredSchemas: [schema],
      requiredSchemas: [
        DesignSchemaRequirement(
          schemaID: schemaID,
          versions: try SchemaVersionRange(
            lowerBound: SchemaVersion(major: 1, minor: 0, patch: 0),
            upperBound: SchemaVersion(major: 2, minor: 0, patch: 0)
          )
        ),
      ],
      offeredCapabilities: capabilities,
      requiredCapabilities: [
        DesignCapabilityRequirement(
          capabilityID: capability.capabilityID,
          versions: capability.versions,
          necessity: .required
        ),
      ]
    )
    guard databaseID.description
            == "00000000000000010000000000000002",
          subjectScopeID.description
            == "00000000000000030000000000000004",
          revision.revisionID.description
            == "00000000000000050000000000000006",
          capabilities.descriptors == [capability],
          report.isCompatible,
          report.agreedSchemas == [schema],
          report.agreedCapabilities == [capability] else {
      throw PortabilityProbeError.canonicalValueMismatch
    }
    return [
      "CircuiteFoundationPortabilityProbe",
      databaseID.description,
      subjectScopeID.description,
      revision.revisionID.description,
      capability.capabilityID.rawValue,
    ].joined(separator: ":")
  }
}

private enum PortabilityProbeError: Error {
  case canonicalValueMismatch
}
