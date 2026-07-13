import Foundation

public struct HierarchyPath: Sendable, Hashable, Codable, CustomStringConvertible {
  public let components: [String]

  public static let root = Self(uncheckedComponents: [])

  public var description: String {
    components.joined(separator: "/")
  }

  public init(components: [String]) throws {
    for component in components {
      let hasControlCharacter = component.unicodeScalars.contains {
        CharacterSet.controlCharacters.contains($0)
      }
      guard !component.isEmpty,
        component.trimmingCharacters(in: .whitespacesAndNewlines) == component,
        component != ".",
        component != "..",
        !component.contains("/"),
        !hasControlCharacter
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

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(try container.decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}
