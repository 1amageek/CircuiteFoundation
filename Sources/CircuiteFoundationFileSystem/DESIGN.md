# CircuiteFoundationFileSystem

## Purpose and Scope

Parent: [CircuiteFoundation](../../DESIGN.md). This existing host implementation
target owns secure root-relative artifact access. Child:
[SourceDiscovery](SourceDiscovery/DESIGN.md). Its existing exact-reference
access API is implemented; the child's unknown-identity discovery API is implemented.

## Responsibilities and Boundaries

Keep descriptor-relative filesystem security, file/session/root lifetime,
bounded reads and typed close failure in this owner. Do not introduce PDK,
SPICE, domain schema, database or flow dependencies. Public shared identity and
budget values remain in Core; local discovery stays in this host product.

## Related Designs

| Design | Relationship | Contract Used | Summary | Cautions |
|---|---|---|---|---|
| [Package](../../DESIGN.md) | parent | Artifact identity, access and target separation | Dependency floor | No host API in portable Core |
| [SourceDiscovery](SourceDiscovery/DESIGN.md) | child | Bounded root discovery | Unknown content acquisition | Requires a new version, not 26.812.0 capability |
| [PDK SourceCapture](../../../PDKKit/Sources/PDKSourceCapture/DESIGN.md) | used by | Exact capture and planned candidate acquisition | Domain admission | Discovery is not approved identity |
| [CoreSpiceIO](../../../CoreSpice/Sources/CoreSpiceIO/DESIGN.md) | used by | Root-relative source acquisition | Independent source consumer | Exact profile resolution has its own authority |

## Architecture

```text
Core identity/budget + explicit root-relative intent
    -> owned ArtifactRootCapability
        -> exact-reference access (current)
        -> bounded discovery/enumeration (SourceDiscovery child)
            -> descriptor-relative file/directory operations -> checked close
```

## Contracts and Invariants

The existing exact-access and target/platform contracts remain owned by the
package's artifact section. SourceDiscovery owns its new behavioral contract;
no duplicated local backend is introduced in a consumer. Public discovery does
not relax the expected-reference access path or authenticate observed bytes.

## State, Ownership, and Lifecycle

Root actors own descriptors and session admission/draining. SourceDiscovery uses
the same shutdown owner rather than independent root/session bookkeeping.
Returned immutable source owners outlive the closed file descriptor. The SourceDiscovery
child owns PN2.0 controlled overloads: external synchronous control gates work before action,
and opaque leases stay with managed source/inventory storage. Root construction remains
composition-owned; every internal traversal descriptor is retained before acquisition.
Standalone per-operation budgets do not establish whole-invocation resource admission.

## Failure, Concurrency, and Constraints

FileSystem is a host product with its declared platform matrix. Unknown-identity
discovery is explicitly unavailable on unsupported backends. It does not change
portable Core storage or synchronization. Session/root termination remains typed,
fallible and awaited; caller-supplied budgets are validated before acquisition.

## Verification and Change Impact

Existing FileSystem behavioral/security tests retain their scope. SourceDiscovery
adds focused tests before either PDK or CoreSpice adopts a new published revision.
Verify Core Native/WASI/Embedded target separation when package products change;
host behavior cannot establish a WASM filesystem capability.
