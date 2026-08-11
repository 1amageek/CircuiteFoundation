import CircuiteFoundationCryptoPortabilityProbeSupport

@main
struct CircuiteFoundationEmbeddedCryptoPortabilityProbe {
  static func main() throws {
    print(try CircuiteFoundationCryptoPortabilityProbeOutput.make())
  }
}
