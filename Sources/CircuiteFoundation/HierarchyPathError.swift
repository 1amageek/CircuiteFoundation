public enum HierarchyPathError: Error, Sendable, Equatable {
  case invalidComponent(String)

  public var errorDescription: String? {
    switch self {
    case .invalidComponent(let component):
      "Invalid hierarchy path component: \(component)"
    }
  }
}
