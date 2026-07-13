import Foundation

public enum ElectricalQuantityError: Error, Sendable, Equatable, LocalizedError {
  case nonFiniteValue(quantity: String, value: Double)

  public var errorDescription: String? {
    switch self {
    case .nonFiniteValue(let quantity, let value):
      "\(quantity) must be finite; received \(value)."
    }
  }
}
