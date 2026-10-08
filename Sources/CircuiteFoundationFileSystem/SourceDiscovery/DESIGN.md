# Bounded Source Discovery

## Purpose and Scope

Status: proposed host API for a future CircuiteFoundation version. Parent:
[FileSystem](../DESIGN.md). No children. Own root-contained discovery of unknown
content and bounded directory inventory. The fixed 26.812.0 API remains unchanged
and cannot be claimed to provide these operations.

## Responsibilities and Boundaries

This generic concept is shared by independent PDK and SPICE input consumers.
It observes immutable bytes, not their domain meaning or approval. Extend the
existing root-capability implementation; consumers use its public API and do
not copy private POSIX access or filesystem state. No new portable Core type is
needed for this host-only operation beyond existing identity/path/budget values.

## Related Designs

| Design | Relationship | Contract Used | Summary | Cautions |
|---|---|---|---|---|
| [FileSystem](../DESIGN.md) | parent | Secure descriptor ownership and shutdown | Host implementation | Expected-reference access stays distinct |
| [PDK LocalCapture](../../../../PDKKit/Sources/PDKSourceCapture/LocalCapture/DESIGN.md) | used by | Proposed ArtifactSourceDiscovering | Candidate input observation | Exact profiles do not discover replacement identities |
| [CoreSpiceIO](../../../../CoreSpice/Sources/CoreSpiceIO/DESIGN.md) | used by | Bounded generic source observation | Caller-owned source input | Grammar/section selection stays outside Foundation |

## Architecture

```text
explicit root ID + validated relative path + descriptor + finite budget
    -> existing secure root -> open descriptor with no-follow traversal
       -> fstat/admit -> bounded pages -> digest owned bytes -> final snapshot
       -> close file -> return ArtifactDiscoveredSource
bounded enumeration -> count every visited entry -> root-relative inventory
```

## Contracts and Invariants

Proposed API vocabulary:

```swift
public protocol ArtifactSourceDiscovering: Sendable {
    func discover(_ intent: ArtifactSourceDiscoveryIntent)
        async throws(ArtifactSourceDiscoveryError) -> ArtifactDiscoveredSource
    func enumerate(_ intent: ArtifactDirectoryInventoryIntent)
        async throws(ArtifactSourceDiscoveryError) -> ArtifactDirectoryInventory
}
```

ArtifactRootCapability conforms using its existing owned root. Discovery intent
contains root ID, ArtifactRelativePath, ArtifactDescriptor and ArtifactAccessBudget.
Inventory intent contains explicit root-relative start, finite visited-entry,
depth/result-count limits and work/duration budget. Input type is separate from
ArtifactAvailability, which already requires known content identity.

FD-01: Root ID matches the owned root; absolute/escaping paths, symlinked path
components and nonregular source files fail. Source security uses the same
descriptor-relative traversal as exact access. No cwd or environment fallback.

FD-02: Read/hash counters cover the actual bytes used to construct the immutable
source. Check declared file size and remaining byte/work/page capacity before
allocation, then enforce limits while reading even if a file grows. Final file
snapshot/size checks and full-buffer identity detect changed/truncated input.
Never return identity from one read with bytes from another pathname lookup.

FD-03: ArtifactDiscoveredSource is a checked immutable Sendable owner containing
full observed reference, scoped byte borrowing and access/work observations.
Its initializer is internal; no Codable can mint it. Successful file close
precedes return. Root lifetime stays with its owner and root shutdown drains both
exact and discovery operations. Primary and close failures are preserved together.
Observed reference remains a discovery result, not an admission credential.

FD-04: Inventory counts every visited directory entry, including rejected names,
before continued enumeration. Directory traversal depth/result/work limits are
finite; overflow, cancellation and deadline exhaustion fail with explicit partial
diagnostic progress and no complete inventory. Deterministic output sorting is
charged to the budget. Do not accumulate an unbounded result before checking limits.

## State, Ownership, and Lifecycle

Reuse root actor session admission and shutdown; an open discovery is included
in the same draining set. File descriptors close exactly once on success, early
exit, failure and cancellation. Source buffers are immutable, owned after file
close and borrowed only within a synchronous closure. Buffer pointer escapes,
unchecked Sendable and target-dependent raw shared state are not introduced.

## Failure, Concurrency, and Constraints

Typed cases distinguish invalid intent/root/path, source type/read/change,
byte/page/work/entry/depth/time limit, cancellation, closed owner and cleanup.
Zero-length source observation is allowed if its exact identity is valid;
domain admission decides whether empty content can satisfy a requirement.
Deadline checks reject late success, not preempt blocked I/O/close. Outer hard
process timeout is a separate owner. Implementation must preserve existing unsafe
boundary ownership/alignment/lifetime checks and run host sanitizers where supported.

## Verification and Change Impact

Planned focused FileSystem source-discovery tests exercise real root escape and
symlink replacement, file growth/truncation, same-length tampering, exact returned
buffer identity, empty input, byte/page/entry/depth/work limits, close failure,
cancellation and root-close/open races. Injection covers deterministic failures;
real descriptor paths prove security. Capture and inventory consumers follow only
after this contract passes and exact-version adoption is available. Do not report
new Foundation behavior from old 26.812.0 tests.
