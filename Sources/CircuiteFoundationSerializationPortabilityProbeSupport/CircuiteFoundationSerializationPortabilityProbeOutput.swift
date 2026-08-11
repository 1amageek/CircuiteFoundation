import CircuiteFoundation
import CircuiteFoundationFoundation
import Foundation

public enum CircuiteFoundationSerializationPortabilityProbeOutput {
  public static func make() throws -> String {
    let identifier = try DesignDatabaseID(high: 1, low: 2)
    let encoded = try JSONEncoder().encode(identifier)
    let decoded = try JSONDecoder().decode(DesignDatabaseID.self, from: encoded)
    let expectedJSON = #""00000000000000010000000000000002""#
    guard decoded == identifier,
          String(decoding: encoded, as: UTF8.self) == expectedJSON else {
      throw SerializationPortabilityProbeError.roundTripMismatch
    }
    return [
      "CircuiteFoundationSerializationPortabilityProbe",
      decoded.description,
    ].joined(separator: ":")
  }
}

private enum SerializationPortabilityProbeError: Error {
  case roundTripMismatch
}
