# CircuiteFoundation Requirements

Status: CF-001 through CF-011 describe the existing responsibility family. CF-012 and later define the planned
breaking contract required by `DesignDatabase`. Completion must be reported per requirement, not for the package as
a whole.

## Functional Requirements

| ID | Requirement |
|---|---|
| CF-001 | Provide a minimal asynchronous `Engine` protocol without persistence or orchestration requirements. |
| CF-002 | Represent artifact semantics, immutable content identity, and availability as separate values. |
| CF-003 | Represent algorithm-qualified content digests without requiring a crypto implementation in the Core target. |
| CF-004 | Provide injectable local artifact access that prevents workspace-root escape and symlink escape. |
| CF-005 | Return artifact integrity failures as typed structured issues. |
| CF-006 | Represent diagnostics with stable codes, severity, typed subjects, and structured actions. |
| CF-007 | Represent execution provenance and evidence without claiming qualification or approval. |
| CF-008 | Separate persistent database entity identity, exact revision-scoped reference, human path addressing, and external object identity. |
| CF-009 | Convert integer database coordinates using a positive finite database-unit scale and explicit rounding. |
| CF-010 | Provide finite SI values only for electrical dimensions unavailable in Foundation. |
| CF-011 | Provide stable semantic schema versions. |
| CF-012 | Provide fixed-width `DesignDatabaseID`, `DesignRevisionID`, and nonzero `DesignEntityID` values with canonical external encodings. |
| CF-013 | Provide `DesignRevisionReference`, `DesignEntityKey`, and exact `DesignEntityReference` without storage or lookup behavior. |
| CF-014 | Provide open validated facet, entity-kind, schema, capability, and external-system identifiers. |
| CF-015 | Provide inclusive-lower / exclusive-upper schema version ranges and deterministic compatibility intersection. |
| CF-016 | Provide capability requirements and a structured negotiation report that cannot silently ignore missing required capabilities. |
| CF-017 | Scope external object identifiers by external system and source digest. |
| CF-018 | Replace ambiguous provenance design digests with typed input and output revision references. |
| CF-019 | Keep artifact content identity independent from local path or remote resource availability. |
| CF-020 | Provide stable serialization fixtures for every database-facing Foundation value. |

## Target Requirements

| ID | Requirement |
|---|---|
| CF-T01 | The `CircuiteFoundation` target contains shared values and protocols only and has no external package dependency. |
| CF-T02 | Crypto implementations are isolated in `CircuiteFoundationCrypto`, which may depend on `swift-crypto`. |
| CF-T03 | Local filesystem implementations are isolated in `CircuiteFoundationFileSystem` and depend on Core protocols. |
| CF-T04 | Domain packages depend directly on the Core product and add implementation products only when used. |

## Quality Requirements

| ID | Requirement |
|---|---|
| CF-Q01 | No target imports an engine, `DesignDatabase`, flow runtime, qualification policy, or UI package. |
| CF-Q02 | All public values are immutable `Sendable`; persistent values are `Codable` and `Hashable`. |
| CF-Q03 | Errors are typed and no error is suppressed with `try?`. |
| CF-Q04 | Public behavior is protocol-first and concrete local / crypto implementations are separately injectable. |
| CF-Q05 | Initializer and decoder validation are identical and have positive and negative fixtures. |
| CF-Q06 | Fixed-width ID encodings round-trip across Swift and an independent non-Swift fixture implementation. |
| CF-Q07 | Core values contain no secret-bearing URL, raw environment, pointer, mutable buffer, or database storage owner. |
| CF-Q08 | Unknown required schemas or capabilities fail explicitly; no compatibility fallback produces success. |
| CF-Q09 | Removal of a database-facing `FIXME(INCOMPLETE_IMPLEMENTATION)` requires success and failure behavior tests plus status updates. |

## Completion Evidence

| Area | Required Evidence |
|---|---|
| Identity | zero rejection, fixed-width encoding, database scope, revision scope, non-reuse contract tests |
| Addressing | entity, path, external subject round trips and invalid cross-kind resolution tests |
| Compatibility | overlap, empty intersection, missing required, unknown optional, digest mismatch tests |
| Artifact | same content at multiple locations retains identity; changed content cannot retain immutable reference |
| Provenance | typed input/output revisions and invalid timestamp tests |
| Dependency | target-level dependency audit proves the Core target does not link crypto or local filesystem implementation products |
| Portability | macOS, WASM, Embedded WASM compile/link checks using the pinned toolchain and SDK |
