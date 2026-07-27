public enum DesignCompatibilityNegotiator {
  public static func negotiate(
    offeredSchemas: [DesignSchemaDescriptor],
    requiredSchemas: [DesignSchemaRequirement],
    offeredCapabilities: DesignCapabilitySet,
    requiredCapabilities: [DesignCapabilityRequirement]
  ) throws(SchemaCompatibilityError) -> DesignCompatibilityReport {
    var schemasByID: [DesignSchemaID: DesignSchemaDescriptor] = [:]
    for descriptor in offeredSchemas {
      guard schemasByID.updateValue(descriptor, forKey: descriptor.schemaID) == nil else {
        throw SchemaCompatibilityError.duplicateSchema(descriptor.schemaID)
      }
    }
    let capabilitiesByID = Dictionary(
      uniqueKeysWithValues: offeredCapabilities.descriptors.map { ($0.capabilityID, $0) }
    )

    var agreedSchemasByID: [DesignSchemaID: DesignSchemaDescriptor] = [:]
    var missingSchemas: [DesignSchemaRequirement] = []
    var incompatibleSchemas: [DesignSchemaRequirement] = []
    var pendingRequirements = Set(requiredSchemas)
    var evaluatedRequirements = Set<DesignSchemaRequirement>()
    while let requirement = pendingRequirements.sorted(by: requirementOrder).first {
      pendingRequirements.remove(requirement)
      guard evaluatedRequirements.insert(requirement).inserted else { continue }
      guard let offered = schemasByID[requirement.schemaID] else {
        missingSchemas.append(requirement)
        continue
      }
      if requirement.versions.contains(offered.version) {
        agreedSchemasByID[offered.schemaID] = offered
        pendingRequirements.formUnion(offered.requiredSchemas)
      } else {
        incompatibleSchemas.append(requirement)
      }
    }

    var agreedCapabilities: [DesignCapabilityDescriptor] = []
    var missingCapabilities: [DesignCapabilityRequirement] = []
    var incompatibleCapabilities: [DesignCapabilityRequirement] = []
    var limitations: [DesignCapabilityRequirement] = []
    for requirement in requiredCapabilities.sorted(by: { $0.capabilityID < $1.capabilityID }) {
      guard let offered = capabilitiesByID[requirement.capabilityID] else {
        if requirement.necessity == .required {
          missingCapabilities.append(requirement)
        } else {
          limitations.append(requirement)
        }
        continue
      }
      guard let intersection = offered.versions.intersection(with: requirement.versions) else {
        if requirement.necessity == .required {
          incompatibleCapabilities.append(requirement)
        } else {
          limitations.append(requirement)
        }
        continue
      }
      agreedCapabilities.append(
        DesignCapabilityDescriptor(
          capabilityID: requirement.capabilityID,
          versions: intersection
        )
      )
    }

    return DesignCompatibilityReport(
      agreedSchemas: agreedSchemasByID.values.sorted { $0.schemaID < $1.schemaID },
      agreedCapabilities: agreedCapabilities,
      missingRequiredSchemas: missingSchemas,
      incompatibleRequiredSchemas: incompatibleSchemas,
      missingRequiredCapabilities: missingCapabilities,
      incompatibleRequiredCapabilities: incompatibleCapabilities,
      limitations: limitations
    )
  }

  private static func requirementOrder(
    _ lhs: DesignSchemaRequirement,
    _ rhs: DesignSchemaRequirement
  ) -> Bool {
    if lhs.schemaID != rhs.schemaID { return lhs.schemaID < rhs.schemaID }
    if lhs.versions.lowerBound != rhs.versions.lowerBound {
      return lhs.versions.lowerBound < rhs.versions.lowerBound
    }
    return lhs.versions.upperBound < rhs.versions.upperBound
  }
}
