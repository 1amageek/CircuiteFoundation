# CircuiteFoundation Remaining Tasks

Updated: 2026-07-27

The database identity and compatibility contracts are implemented. The remaining work is target isolation,
artifact identity/availability separation, cross-language fixtures, portability evidence, and completion of
consumer compilation after the breaking provenance migration.

## Remaining tasks

| ID | Priority | Remaining implementation | Completion evidence |
|---|---|---|---|
| CF-DB-5 | P1 | Separate artifact identity from availability | same-content / multi-location and tamper tests |
| CF-DB-6 | P1 | Split Core, Crypto, FileSystem targets | dependency graph audit and independent builds |
| CF-DB-7 | P1 | Add cross-language canonical encoding fixtures | Swift and independent fixture agreement |
| CF-DB-8 | P1 | Verify macOS, WASM, Embedded WASM compile/link | pinned toolchain / SDK logs |
| CF-DB-9 | P1 | Finish compile/test migration of every provenance consumer | workspace-wide package build matrix |

## Completed P1 work

| ID | Completed | Evidence |
|---|---|---|
| CF-W1 | 2026-07-26 | `scripts/check-p0-p1-migration-gates.py --workspace /Users/1amageek/Desktop/LSI --json` passed with zero findings; `GOAL_STATUS.md` and `docs/circuite-foundation-design.md` now record migration completion. |
| CF-DB-1 | 2026-07-27 | Fixed-width identities and exact reference serialization/invalid-input fixtures |
| CF-DB-2 | 2026-07-27 | Ambiguous object reference removed; entity/path/external tagged subjects added |
| CF-DB-3 | 2026-07-27 | Schema/capability negotiation and incompatibility fixtures |
| CF-DB-4 | 2026-07-27 | Provenance contract now carries separate typed input/output design revisions |

## External Prerequisites

Consumer migrations must be coordinated because backward compatibility is intentionally not retained. Domain
behavior, database storage, and concrete workspace persistence must not move into `CircuiteFoundation`.

## Evidence reviewed

- `GOAL_STATUS.md`
- `README.md`
- Public declarations and focused Foundation tests
- `Sources` incomplete-implementation marker scan
