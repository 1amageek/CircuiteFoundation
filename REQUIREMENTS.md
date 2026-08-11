# CircuiteFoundation Requirements

Status: CF-001 through CF-011 describe the existing responsibility family. CF-012 and later define the planned
breaking contract required by `DesignDatabase`. Completion must be reported per requirement, not for the package as
a whole.

## Functional Requirements

| ID | Requirement |
|---|---|
| CF-001 | Provide a minimal asynchronous `Engine` protocol without persistence or orchestration requirements. |
| CF-002 | Represent artifact descriptor semantics, immutable content identity, and availability as three separate value families. |
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
| CF-019 | Require one content-derived artifact ID to remain byte-identical across every local or service availability and prohibit producer/path-derived IDs. |
| CF-020 | Provide stable serialization fixtures for every database-facing Foundation value. |
| CF-021 | Provide a distinct nonzero 128-bit `DesignAuthorizationSubjectScopeID` with canonical 32-lowercase-hex encoding for cross-package operation references; it contains no policy or direct identifying plaintext and grants no authority. |

## Target Requirements

| ID | Requirement |
|---|---|
| CF-T01 | The `CircuiteFoundation` target contains shared values/protocols only, imports the Swift Standard Library only, and has no external package dependency. |
| CF-T01A | Foundation URL/Date/UUID/Measurement/LocalizedError conversions live only in optional `CircuiteFoundationFoundation` and cannot define canonical identity or I/O semantics. |
| CF-T02 | Crypto implementations are isolated in `CircuiteFoundationCrypto`, which may depend on `swift-crypto`. |
| CF-T03 | Local filesystem implementations are isolated in `CircuiteFoundationFileSystem` and depend on Core protocols. |
| CF-T04 | Domain packages depend directly on the Core product and add implementation products only when used. |
| CF-T05 | Keep an in-memory incremental `ContentDigesting` session as the injected Core contract; concrete SHA-256 construction belongs to `CircuiteFoundationCrypto`, and high-volume consumers hash bounded updates without whole-artifact concatenation. |
| CF-T06 | Keep path/URL opening, root validation, file reads, and streamed file hashing out of the Core digest protocol and inside `CircuiteFoundationFileSystem`. |
| CF-T07 | FileSystem opens an owned root capability and performs component-relative no-follow traversal, pre/post metadata and hashing on the same file handle, lease drain, and fallible close; unsupported platforms fail rather than using resolve-then-reopen. |

## Quality Requirements

| ID | Requirement |
|---|---|
| CF-Q01 | No target imports an engine, `DesignDatabase`, flow runtime, qualification policy, or UI package. |
| CF-Q02 | Core persistent/control values are immutable `Sendable` and `Hashable`; host serialization adapters add explicit `Codable` conformances without changing Core identity or validation. An explicitly task-owned noncopyable incremental session may be mutable but cannot be persisted, copied, shared, or escape its scoped lifetime. |
| CF-Q03 | Errors are typed and no error is suppressed with `try?`. |
| CF-Q04 | Public behavior is protocol-first and concrete local / crypto implementations are separately injectable. |
| CF-Q05 | Initializer and decoder validation are identical and have positive and negative fixtures. |
| CF-Q06 | Fixed-width ID encodings round-trip across Swift and an independent non-Swift fixture implementation. |
| CF-Q07 | Core values contain no secret-bearing URL, raw environment, pointer, mutable buffer, or database storage owner. |
| CF-Q08 | Unknown required schemas or capabilities fail explicitly; no compatibility fallback produces success. |
| CF-Q09 | Removal of a database-facing `FIXME(INCOMPLETE_IMPLEMENTATION)` requires success and failure behavior tests plus status updates. |
| CF-Q10 | Artifact access sessions are reference-, generation-, and budget-bound, return bounded owner-backed pages, and expose fallible asynchronous termination without returning paths, credentials, or raw handles. |
| CF-Q11 | Authorization-scope initializer and decoder validation are identical; all-zero, wrong-length, uppercase, and non-hex encodings fail, and no API treats the value as authentication or a bearer credential. |

## Requirement State Ledger

This ledger reports design and implementation separately; a normative target design is not implementation
evidence.

| Requirement | State | Current evidence / remaining gate |
|---|---|---|
| CF-001 | Implemented | existing `Engine` declaration and tests |
| CF-002 | Implemented | content-derived `ArtifactReference`, semantic `ArtifactDescriptor`, and separate `ArtifactAvailability` |
| CF-003 | Implemented | implementation-free Core digest protocol/session and separate Crypto implementation product |
| CF-004 | Implemented | root capability, descriptor-relative no-follow traversal, and same-handle access contract |
| CF-005 | Implemented | typed integrity, mutation, access-budget, termination, close, and compound failures |
| CF-006 | Implemented | diagnostic value and typed subject fixtures |
| CF-007 | Implemented | evidence/provenance values do not grant approval |
| CF-008 | Implemented | entity/path/external identity split |
| CF-009 | Implemented | checked DBU conversion fixtures |
| CF-010 | Implemented | finite electrical value fixtures |
| CF-011 | Implemented | semantic schema version |
| CF-012 | Implemented | fixed-width database/revision/entity IDs |
| CF-013 | Implemented | exact revision/entity references |
| CF-014 | Implemented | validated open identifiers |
| CF-015 | Implemented | range intersection fixtures |
| CF-016 | Implemented | structured compatibility negotiation |
| CF-017 | Implemented | scoped external identity |
| CF-018 | Implemented | typed input/output revision provenance |
| CF-019 | Implemented | content-derived ID and multi-availability invariant are represented by separate public types |
| CF-020 | Partial | explicit adapters and positive/negative identity, compatibility, artifact, access, and evidence fixtures exist; the fixed product-by-product Native/WASI/Embedded matrix is recorded, while independent cross-language fixture agreement remains |
| CF-021 | Implemented | validated nonzero value, canonical single-string Codable, invalid-input fixtures, and DesignDatabase operation-reference integration |
| CF-T01, CF-T01A, CF-T02...T07 | Implemented for the fixed matrix | Core/serialization/Foundation/Crypto/FileSystem responsibilities, exact digest API, secure filesystem contract, and supported/unsupported product cells are exercised in `PORTABILITY_MATRIX.md` |
| CF-Q01...Q10 | Acceptance contract | each applicable row must be evidenced by the completion matrix below |

## Completion Evidence

| Area | Required Evidence |
|---|---|
| Identity | zero rejection, fixed-width encoding, database scope, revision scope, non-reuse contract tests |
| Authorization scope identity | nonzero/canonical/invalid decoding, same-value cross-language fixture, no direct identifying plaintext, and no-authority behavior |
| Addressing | entity, path, external subject round trips and invalid cross-kind resolution tests |
| Compatibility | overlap, empty intersection, missing required, unknown optional, digest mismatch tests |
| Artifact | same content at multiple locations retains identity; changed content cannot retain immutable reference |
| Digest | existential use through `any ContentDigesting`, limit/overflow/use-after-scope/finalize/abort vectors, and bounded multi-chunk equality with an independent SHA-256 fixture |
| Filesystem | symlink/reparse race corpus, component replacement race, same-handle pre/post metadata, cancellation, read-plus-close compound failure, lease drain, and unsupported-platform failure |
| Access | local/service sessions preserve exact reference/generation, byte/page/work budgets and final receipt; continuation and termination cannot leak credentials or handles |
| Provenance | typed input/output revisions and invalid timestamp tests |
| Dependency | target-level dependency audit proves the Core target does not link crypto or local filesystem implementation products |
| Portability | product-by-product macOS/WASI/Embedded matrix from `DESIGN.md` and `PORTABILITY_MATRIX.md`, with exact toolchain/SDK compile/link logs and runtime evidence where executable |
