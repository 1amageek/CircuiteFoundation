public protocol Engine<Request, Output>: Sendable {
  associatedtype Request: Sendable
  associatedtype Output: Sendable

  func execute(_ request: Request) async throws -> Output
}
