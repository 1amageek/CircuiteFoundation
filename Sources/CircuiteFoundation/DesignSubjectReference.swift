import Foundation

public enum DesignSubjectReference: Sendable, Hashable, Codable {
  case entity(DesignEntityReference)
  case path(DesignPathReference)
  case external(ExternalObjectReference)

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Kind.self, forKey: .kind) {
    case .entity:
      self = .entity(try container.decode(DesignEntityReference.self, forKey: .entity))
    case .path:
      self = .path(try container.decode(DesignPathReference.self, forKey: .path))
    case .external:
      self = .external(try container.decode(ExternalObjectReference.self, forKey: .external))
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .entity(let value):
      try container.encode(Kind.entity, forKey: .kind)
      try container.encode(value, forKey: .entity)
    case .path(let value):
      try container.encode(Kind.path, forKey: .kind)
      try container.encode(value, forKey: .path)
    case .external(let value):
      try container.encode(Kind.external, forKey: .kind)
      try container.encode(value, forKey: .external)
    }
  }

  private enum Kind: String, Codable {
    case entity
    case path
    case external
  }

  private enum CodingKeys: String, CodingKey {
    case kind
    case entity
    case path
    case external
  }
}
