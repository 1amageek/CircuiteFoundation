public enum InteroperabilityBackend: Sendable, Hashable {
  case native
  case external(ExternalSystemID)
}
