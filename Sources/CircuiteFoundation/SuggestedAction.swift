public struct SuggestedAction: Sendable, Hashable {
  public let code: String
  public let summary: String

  public init(code: String, summary: String) {
    self.code = code
    self.summary = summary
  }
}
