public struct DesignCompatibilityReport: Sendable, Hashable {
  public let agreedSchemas: [DesignSchemaDescriptor]
  public let agreedCapabilities: [DesignCapabilityDescriptor]
  public let missingRequiredSchemas: [DesignSchemaRequirement]
  public let incompatibleRequiredSchemas: [DesignSchemaRequirement]
  public let missingRequiredCapabilities: [DesignCapabilityRequirement]
  public let incompatibleRequiredCapabilities: [DesignCapabilityRequirement]
  public let limitations: [DesignCapabilityRequirement]

  public var isCompatible: Bool {
    missingRequiredSchemas.isEmpty
      && incompatibleRequiredSchemas.isEmpty
      && missingRequiredCapabilities.isEmpty
      && incompatibleRequiredCapabilities.isEmpty
  }

  public init(
    agreedSchemas: [DesignSchemaDescriptor],
    agreedCapabilities: [DesignCapabilityDescriptor],
    missingRequiredSchemas: [DesignSchemaRequirement],
    incompatibleRequiredSchemas: [DesignSchemaRequirement],
    missingRequiredCapabilities: [DesignCapabilityRequirement],
    incompatibleRequiredCapabilities: [DesignCapabilityRequirement],
    limitations: [DesignCapabilityRequirement]
  ) {
    self.agreedSchemas = agreedSchemas
    self.agreedCapabilities = agreedCapabilities
    self.missingRequiredSchemas = missingRequiredSchemas
    self.incompatibleRequiredSchemas = incompatibleRequiredSchemas
    self.missingRequiredCapabilities = missingRequiredCapabilities
    self.incompatibleRequiredCapabilities = incompatibleRequiredCapabilities
    self.limitations = limitations
  }
}
