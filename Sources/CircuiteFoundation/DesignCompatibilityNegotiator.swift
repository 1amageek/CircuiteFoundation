public enum DesignCompatibilityNegotiator {
  public static func negotiate(
    offeredSchemas: [DesignSchemaDescriptor],
    requiredSchemas: [DesignSchemaRequirement],
    offeredCapabilities: DesignCapabilitySet,
    requiredCapabilities: [DesignCapabilityRequirement]
  ) throws(SchemaCompatibilityError) -> DesignCompatibilityReport {
    let orderedOfferedSchemas = offeredSchemas.sorted {
      $0.schemaID < $1.schemaID
    }
    for index in orderedOfferedSchemas.indices.dropFirst()
      where orderedOfferedSchemas[index - 1].schemaID
        == orderedOfferedSchemas[index].schemaID {
      throw SchemaCompatibilityError.duplicateSchema(
        orderedOfferedSchemas[index].schemaID
      )
    }

    var agreedSchemas: [DesignSchemaDescriptor] = []
    var missingSchemas: [DesignSchemaRequirement] = []
    var incompatibleSchemas: [DesignSchemaRequirement] = []
    var pendingRequirements = uniqueRequirements(requiredSchemas)
    var evaluatedRequirements: [DesignSchemaRequirement] = []
    while !pendingRequirements.isEmpty {
      let requirement = pendingRequirements.removeFirst()
      guard !evaluatedRequirements.contains(requirement) else { continue }
      evaluatedRequirements.append(requirement)
      guard let offered = orderedOfferedSchemas.first(where: {
        $0.schemaID == requirement.schemaID
      }) else {
        missingSchemas.append(requirement)
        continue
      }
      if requirement.versions.contains(offered.version) {
        if !agreedSchemas.contains(where: { $0.schemaID == offered.schemaID }) {
          agreedSchemas.append(offered)
        }
        for transitive in offered.requiredSchemas
          where !pendingRequirements.contains(transitive)
            && !evaluatedRequirements.contains(transitive) {
          pendingRequirements.append(transitive)
        }
        pendingRequirements.sort(by: requirementOrder)
      } else {
        incompatibleSchemas.append(requirement)
      }
    }

    var agreedCapabilities: [DesignCapabilityDescriptor] = []
    var missingCapabilities: [DesignCapabilityRequirement] = []
    var incompatibleCapabilities: [DesignCapabilityRequirement] = []
    var limitations: [DesignCapabilityRequirement] = []
    for requirement in requiredCapabilities.sorted(by: { $0.capabilityID < $1.capabilityID }) {
      guard let offered = offeredCapabilities.descriptors.first(where: {
        $0.capabilityID == requirement.capabilityID
      }) else {
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
      agreedSchemas: agreedSchemas.sorted { $0.schemaID < $1.schemaID },
      agreedCapabilities: agreedCapabilities,
      missingRequiredSchemas: missingSchemas,
      incompatibleRequiredSchemas: incompatibleSchemas,
      missingRequiredCapabilities: missingCapabilities,
      incompatibleRequiredCapabilities: incompatibleCapabilities,
      limitations: limitations
    )
  }

  private static func uniqueRequirements(
    _ requirements: [DesignSchemaRequirement]
  ) -> [DesignSchemaRequirement] {
    var result: [DesignSchemaRequirement] = []
    for requirement in requirements.sorted(by: requirementOrder)
      where !result.contains(requirement) {
      result.append(requirement)
    }
    return result
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
