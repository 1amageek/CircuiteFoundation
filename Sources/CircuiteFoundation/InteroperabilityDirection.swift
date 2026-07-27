public enum InteroperabilityDirection: String, Sendable, Hashable, Codable {
  case importToLSI
  case exportFromLSI
  case roundTrip
  case differentialComparison
}
