import Foundation

public struct DesignObjectReference: Sendable, Hashable, Codable {
  public let kind: DesignObjectKind
  public let identifier: String
  public let hierarchy: HierarchyPath

  public init(
    kind: DesignObjectKind,
    identifier: String,
    hierarchy: HierarchyPath = .root
  ) throws {
    try TokenValidation.validate(identifier, kind: "Design object identifier")
    self.kind = kind
    self.identifier = identifier
    self.hierarchy = hierarchy
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      kind: container.decode(DesignObjectKind.self, forKey: .kind),
      identifier: container.decode(String.self, forKey: .identifier),
      hierarchy: container.decode(HierarchyPath.self, forKey: .hierarchy)
    )
  }

  private enum CodingKeys: String, CodingKey {
    case kind
    case identifier
    case hierarchy
  }
}
