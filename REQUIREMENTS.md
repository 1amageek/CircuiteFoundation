# Requirements

## Functional requirements

| ID | Requirement |
|---|---|
| CF-001 | Provide a minimal asynchronous `Engine` protocol without persistence or orchestration requirements. |
| CF-002 | Represent artifact intent separately from verified immutable artifact identity. |
| CF-002a | Represent an open validated artifact role in both artifact intent and immutable artifact references. |
| CF-003 | Compute and validate algorithm-qualified SHA-256 digests without loading an entire file into memory. |
| CF-004 | Prevent workspace-relative artifact paths from escaping the selected workspace root. |
| CF-005 | Return artifact integrity failures as typed, structured issues. |
| CF-006 | Represent diagnostics with stable codes, severity, optional design subject, and structured actions. |
| CF-007 | Represent execution provenance and evidence without claiming qualification or approval. |
| CF-007a | Record typed invocation and sanitized execution-environment identity for reproducibility. |
| CF-008 | Provide stable hierarchical design-object addressing across logic and physical domains. |
| CF-009 | Convert integer database coordinates to and from `Measurement<UnitLength>` using a positive finite database-unit scale and explicit rounding. |
| CF-010 | Provide finite SI value types only for electrical dimensions unavailable in Foundation. |
| CF-011 | Provide a stable comparable schema version, including the schema 2 provenance and artifact-role fields. |

## Quality requirements

| ID | Requirement |
|---|---|
| CF-Q01 | The package has no package dependencies and no upward dependency on an engine or orchestrator. |
| CF-Q02 | All public values are `Sendable`; persistent values are `Codable` and `Hashable`. |
| CF-Q03 | Errors are typed and no error is suppressed with `try?`. |
| CF-Q04 | Public behavior is protocol-first and concrete local implementations are separately injectable. |
| CF-Q05 | Serialized forms and boundary validation have regression tests. |
