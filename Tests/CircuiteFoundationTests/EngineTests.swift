import CircuiteFoundation
import Testing

@Suite
struct EngineTests {
  @Test
  func minimalEngineExecutesDomainRequest() async throws {
    let engine = EchoEngine()

    let output = try await engine.execute(EchoRequest(value: 41))

    #expect(output.value == 42)
  }
}

private struct EchoRequest: Sendable {
  let value: Int
}

private struct EchoOutput: Sendable {
  let value: Int
}

private struct EchoEngine: Engine {
  func execute(_ request: EchoRequest) async throws -> EchoOutput {
    EchoOutput(value: request.value + 1)
  }
}
