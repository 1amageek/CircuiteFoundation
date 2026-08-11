public struct ArtifactAccessIntent: Sendable, Hashable {
  public let expectedReference: ArtifactReference
  public let availability: ArtifactAvailability
  public let operation: ArtifactAccessOperation
  public let budget: ArtifactAccessBudget

  public init(
    expectedReference: ArtifactReference,
    availability: ArtifactAvailability,
    operation: ArtifactAccessOperation,
    budget: ArtifactAccessBudget
  ) throws {
    guard expectedReference.id == availability.artifactID else {
      throw ArtifactAccessIntentError.availabilityIdentityMismatch(
        expected: expectedReference.id,
        actual: availability.artifactID
      )
    }
    self.expectedReference = expectedReference
    self.availability = availability
    self.operation = operation
    self.budget = budget
  }

}
