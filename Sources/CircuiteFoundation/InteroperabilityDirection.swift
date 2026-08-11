public enum InteroperabilityDirection: String, Sendable, Hashable {
  case importToLSI
  case exportFromLSI
  case roundTrip
  case differentialComparison
}
