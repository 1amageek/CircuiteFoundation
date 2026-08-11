public enum DesignSubjectReference: Sendable, Hashable {
  case entity(DesignEntityReference)
  case path(DesignPathReference)
  case external(ExternalObjectReference)

}
