public enum InteroperabilityBackend: Sendable, Hashable, Codable {
  case native
  case external(ExternalSystemID)
}
