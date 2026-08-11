public enum SchemaCompatibilityError: Error, Sendable, Equatable {
  case invalidVersionRange(lowerBound: SchemaVersion, upperBound: SchemaVersion)
  case duplicateSchema(DesignSchemaID)
  case duplicateCapability(DesignCapabilityID)

  public var errorDescription: String? {
    switch self {
    case .invalidVersionRange(let lowerBound, let upperBound):
      return "Schema version range [\(lowerBound), \(upperBound)) is empty or reversed."
    case .duplicateSchema(let identifier):
      return "Schema \(identifier.rawValue) is duplicated."
    case .duplicateCapability(let identifier):
      return "Capability \(identifier.rawValue) is duplicated."
    }
  }
}
