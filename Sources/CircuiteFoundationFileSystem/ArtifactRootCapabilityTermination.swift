public actor ArtifactRootCapabilityTermination {
  private let task: Task<Result<Void, ArtifactRootCapabilityError>, Never>

  init(task: Task<Result<Void, ArtifactRootCapabilityError>, Never>) {
    self.task = task
  }

  public func wait() async throws(ArtifactRootCapabilityError) {
    switch await task.value {
    case .success:
      return
    case .failure(let error):
      throw error
    }
  }
}
