# Bounded Source Discovery

## Purpose and Scope

Status: implemented host API, requiring adoption of this exact commit or a subsequent version. Parent:
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
| [PDK LocalCapture](../../../../PDKKit/Sources/PDKSourceCapture/LocalCapture/DESIGN.md) | used by | ArtifactSourceDiscovering | Candidate input observation | Exact profiles do not discover replacement identities |
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

Public API vocabulary:

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
Inventory intent contains explicit root-relative start (nil means the owned root), finite visited-entry,
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

Focused FileSystem source-discovery tests exercise real root escape and
symlink replacement, file growth/truncation, same-length tampering, exact returned
buffer identity, empty input, byte/page/entry/depth/work limits, close failure,
cancellation and root-close/open races. Injection covers deterministic failures;
real descriptor paths prove security. Capture and inventory consumers follow only
after this contract passes and exact-version adoption is available. Do not report
new Foundation behavior from old 26.812.0 tests.

## Implementation Accounting and Isolation

`ArtifactRootCapability` serializes discovery/inventory as synchronous actor-isolated operations.
They have no suspension while descriptors are acquired, consumed, and closed: a queued root close
cannot destroy the root before cleanup finishes, and closed roots reject new operations. The existing
active exact-session draining set remains authoritative for asynchronous sessions.

Discovery charges traversal/duplication, metadata, final close, read and hash update units. Pages
are immutable arrays retained without content copying between read and hash. `withUnsafeBytePages`
borrows those pages directly; the optional contiguous `withUnsafeBytes` consumer boundary explicitly
materializes multiple pages. Source size, page count, work and platform indexing are admitted before
allocation. Inventory counts every `readdir` record (including dot and rejected names), charges name
validation bytes, metadata, descriptor traversal, EOF probes and merge-sort key bytes/moves. An
entry-limit failure reports the triggering observed entry and returns no complete inventory.
Depth zero names the start directory; a directory at the maximum traversal depth fails rather than
claiming an incomplete recursive inventory. Symlinks are reported, never followed.

| State | Native storage/isolation | WASM / Embedded |
|---|---|---|
| Root FD and admission | Existing root actor | FileSystem product unavailable |
| Source pages | Immutable Sendable arrays | FileSystem product unavailable |
| Inventory counters/FD cursors | Local value, synchronous actor call | FileSystem product unavailable |

No conditional synchronization/conformance, raw shared mutable state, unchecked Sendable or portable
Core changes are introduced. Deadline checks use a monotonic clock and reject late success after
cleanup; they do not preempt blocked filesystem calls.

## Behavioral Evidence

The test owner is [ArtifactSourceDiscoveryTests](../../../Tests/CircuiteFoundationTests/ArtifactSourceDiscoveryTests.swift).
On Swift 6.4.0 release, macOS arm64, the new suite and existing FileSystem suite passed 17
methods (the mutation method additionally runs four cases) under ordinary execution, Address
Sanitizer, and Thread Sanitizer. The full package passed 91 methods. Builds and runtime tests
are separate processes with outer limits of 180/240 seconds and 60 seconds respectively.

| Contract | Counterexample rejected by the test owner |
|---|---|
| FD-01 | Wrong root, escaping path, terminal/intermediate symlink, FIFO |
| FD-02 | Growth, truncation before read, same-length mutation, symlink replacement, unadmitted byte/page/work capacity, deadline |
| FD-03 | Root shutdown racing cancellation; retained bytes after root close; primary and close failure preservation |
| FD-04 | Rejected control-character names and dot records counted; entry/depth/result/work/deadline/cancel errors; deterministic repeated inventory and charged sort |

APFS rejected creating an invalid UTF-8 filename; that filesystem-specific fixture is not claimed
as runtime evidence. Valid UTF-8 with a Core-rejected control character is exercised through the
real descriptor enumeration path. Cleanup failure injection tests the shared checked-close
boundary; real success/failure traversal tests execute Darwin descriptor operations.
