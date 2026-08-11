import CircuiteFoundationPortabilityProbeSupport

@main
struct CircuiteFoundationEmbeddedPortabilityProbe {
  static func main() throws {
    print(try CircuiteFoundationPortabilityProbeOutput.make())
  }
}
