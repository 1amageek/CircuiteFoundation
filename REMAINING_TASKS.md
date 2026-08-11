# CircuiteFoundation Remaining Tasks

Updated: 2026-08-11

The database identity, target isolation, location-independent artifact access, and incremental digest contracts
are implemented. Remaining work is cross-language fixture coverage, completion of the consumer migration,
and measured digest-path optimization.

## Remaining tasks

| ID | Priority | Remaining implementation | Completion evidence |
|---|---|---|---|
| CF-DB-7 | P1 | Add cross-language canonical encoding fixtures | Swift and independent fixture agreement |
| CF-DB-9 | P1 | Finish compile/test migration of every provenance consumer | workspace-wide package build matrix |
| CF-DB-11 | P1 | Optimize the measured digest hot path with borrowed spans/zero-copy updates where the baseline session still exceeds allocation/copy budgets | retained before/after allocation, copy, throughput, and lifetime-safety evidence |

## Completed P0 work

| ID | Completed | Evidence |
|---|---|---|
| CF-DB-5 | 2026-08-09 | Content-derived `ArtifactReference` and separate local/service `ArtifactAvailability` contracts |
| CF-DB-6 | 2026-08-09 | Four-product target split and Native/WASI dependency builds |
| CF-DB-10 | 2026-08-09 | Closure-scoped incremental digest session in Core; Foundation/file conversion outside Core |
| CF-DB-12 | 2026-08-09 | Root-capability filesystem access with typed race, budget, integrity, termination, and close failures |
| CF-DB-13 | 2026-08-09 | Bounded owner-backed artifact read session/page/receipt and availability separation |

## Completed P1 work

| ID | Completed | Evidence |
|---|---|---|
| CF-W1 | 2026-07-26 | `scripts/check-p0-p1-migration-gates.py --workspace /Users/1amageek/Desktop/LSI --json` passed with zero findings; `GOAL_STATUS.md` and `docs/circuite-foundation-design.md` now record migration completion. |
| CF-DB-1 | 2026-07-27 | Fixed-width identities and exact reference serialization/invalid-input fixtures |
| CF-DB-2 | 2026-07-27 | Ambiguous object reference removed; entity/path/external tagged subjects added |
| CF-DB-3 | 2026-07-27 | Schema/capability negotiation and incompatibility fixtures |
| CF-DB-4 | 2026-07-27 | Provenance contract now carries separate typed input/output design revisions |
| CF-DB-14 | 2026-07-31 | Validated nonzero opaque authorization-subject scope, canonical lowercase hexadecimal Codable, invalid-input fixtures, and DesignDatabase scoped operation-reference integration |
| CF-DB-15 | 2026-08-11 | Removed serialization runtime protocols from Core, added explicit host adapters with decoder revalidation, and verified byte-identical Native/WASI/Embedded Core probe output |
| CF-DB-8 | 2026-08-11 | Recorded the fixed Native/WASI/Embedded compile/link/runtime matrix for Core, host serialization, Crypto, and secure FileSystem; unsupported Crypto profiles now return typed `backendUnavailable` without fallback, and Native FileSystem security success/failure paths execute |

## External Prerequisites

Consumer migrations must be coordinated because backward compatibility is intentionally not retained. Domain
behavior, database storage, and concrete workspace persistence must not move into `CircuiteFoundation`.

## Evidence reviewed

- `GOAL_STATUS.md`
- `README.md`
- Public declarations and focused Foundation tests
- `Sources` incomplete-implementation marker scan
