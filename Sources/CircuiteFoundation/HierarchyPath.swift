public struct HierarchyPath: Sendable, Hashable, CustomStringConvertible {
  public let components: [String]

  public static let root = Self(uncheckedComponents: [])

  public var description: String {
    components.joined(separator: "/")
  }

  public init(components: [String]) throws {
    for component in components {
      guard !component.isEmpty,
        !TokenValidation.hasBoundaryWhitespace(component),
        component != ".",
        component != "..",
        !component.contains("/"),
        !TokenValidation.containsControlCharacter(component)
      else {
        throw HierarchyPathError.invalidComponent(component)
      }
    }
    self.components = components
  }

  private init(uncheckedComponents components: [String]) {
    self.components = components
  }

  public init(_ serializedValue: String) throws {
    if serializedValue.isEmpty {
      try self.init(components: [])
    } else {
      try self.init(
        components: serializedValue.split(separator: "/", omittingEmptySubsequences: false).map(
          String.init)
      )
    }
  }

  public func appending(_ component: String) throws -> Self {
    try Self(components: components + [component])
  }

}
