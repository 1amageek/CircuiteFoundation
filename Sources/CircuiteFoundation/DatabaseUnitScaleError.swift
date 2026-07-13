import Foundation

public enum DatabaseUnitScaleError: Error, Sendable, Equatable, LocalizedError {
  case invalidScale(Double)
  case nonFiniteLength(Double)
  case valueOutOfRange(Double)

  public var errorDescription: String? {
    switch self {
    case .invalidScale(let value):
      "Database units per micrometer must be finite and greater than zero; received \(value)."
    case .nonFiniteLength(let value):
      "Length must be finite; received \(value)."
    case .valueOutOfRange(let value):
      "Length cannot be represented as Int64 database units: \(value)."
    }
  }
}
