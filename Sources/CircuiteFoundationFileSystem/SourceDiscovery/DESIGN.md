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

Public API vocabulary (PN2.0 cooperative invocation accounting):

```swift
public protocol ArtifactSourceDiscovering: Sendable {
    func discover(_ intent: ArtifactSourceDiscoveryIntent)
        async throws(ArtifactSourceDiscoveryError) -> ArtifactDiscoveredSource
    func discover(_ intent: ArtifactSourceDiscoveryIntent, control: any ArtifactSourceControl)
        async throws(ArtifactSourceDiscoveryError) -> ArtifactDiscoveredSource
    func enumerate(_ intent: ArtifactDirectoryInventoryIntent)
        async throws(ArtifactSourceDiscoveryError) -> ArtifactDirectoryInventory
    func enumerate(_ intent: ArtifactDirectoryInventoryIntent, control: any ArtifactSourceControl)
        async throws(ArtifactSourceDiscoveryError) -> ArtifactDirectoryInventory
}
public protocol ArtifactSourceControl: Sendable {
    func check() throws(ArtifactSourceControlError)
    func charge(_ work: ArtifactSourceWork) throws(ArtifactSourceControlError)
    func retain(_ extent: ArtifactSourceExtent)
        throws(ArtifactSourceControlError) -> any ArtifactSourceRetention
}
public protocol ArtifactSourceRetention: Sendable {}
```

Control is a trusted synchronous injected owner. It atomically admits the supplied planned work
before the action; readBytes, hashedBytes, pages, workUnits and visitedEntries are cumulative
and never refunded. `retain` reserves ownedBytes, temporaryBytes or openResources capacity and
returns an opaque Sendable lifetime handle; capacity releases only at last shared owner release.
Its callbacks do not perform filesystem I/O or wait for the root actor and are invoked outside
any Mutex critical section. Foundation owns neither caller policy nor the control's counters.
Typed control failures preserve quota resource/limit/attempt, overflow, cancellation, deadline,
closed owner and unsupported capability, including when descriptor cleanup also fails.

Uncontrolled overloads retain their per-operation finite budgets and make no whole-invocation
claim. Controlled overloads execute the same descriptor backend with caller admission points.

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
borrows those pages directly. `ArtifactDiscoveredSource` no longer conforms to the rethrows-only
`ArtifactOwnedBytes` protocol: `withUnsafeBytes` is throwing and rejects a controlled multi-page
materialization with a typed capability error. `withAccountedUnsafeBytes` is the explicit throwing
controlled copy boundary and reserves its temporary extent and copy work before allocation. Source size, page count, work and platform indexing are admitted before
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

## PN2.0 Admission Points and Managed Extents

| Action | Planned cumulative work before action | Capacity held for actual lifetime |
|---|---|---|
| Secure path traversal | Per descriptor acquisition/traversal operation | Every duplicate/open descriptor, including two overlapping traversal descriptors |
| Read chunk after secure fstat | Exact chunk read bytes, one page and read work | Page payload and page/container managed slots before allocation/growth |
| Hash update | Actual retained page byte count and hash work | Existing page owner; no second payload |
| Directory probe | One readdir operation before syscall | Existing directory stream |
| Nonnil directory record | One visited entry before validation or name/metadata/result growth | Name/path and result managed extents before construction |
| Sort | Comparison/key-byte/copy work before comparison, join or append | Bounded output/container/key extents before allocation |
| Explicit contiguous copy | Actual source byte count of copy work | Full temporary source extent through callback |

Directory EOF is charged as probe work only, never as a phantom visited entry. Rejected names
and dot records consume visitedEntries. Work is admitted per actual planned action, not by
consuming the entire caller-selected maximum ceiling. Failed actions retain committed planned
work. A source's immutable shared storage owns page and container retention handles; copied
source values share that storage, and dropping one copy cannot release retained capacity.
Inventory entries carry immutable retention handles, so copied inventories, escaped entry arrays,
and copied entries keep result extents alive. Extracting plain path values is a caller-owned output
boundary; callers account any independently retained or transformed values. Temporary extents and descriptors release
on success, cancellation and typed failure; cleanup still runs when control admission rejects.

Managed byte extents count logical payload and declared container/string slots. Each inventory
entry accounts its complete logical path, including ancestor string bytes even when backing is
shared. Standard Library capacity rounding, allocator metadata, opaque directory stream buffers,
and host/runtime overhead are separate from this declared extent contract; it is not a process-RSS
bound. Checked overflow precedes cost construction, reservation and container growth.
Root construction belongs to composition; controlled traversal resources belong to this owner.

PN2.0 verification on Swift 6.4.0 release, macOS 27.0.1 arm64 passed all 95 native methods.
The SourceDiscovery and existing FileSystem suites passed 21 methods each under ASan and TSan;
the mutation method runs four cases. Builds were separate from runtime (180/240-second build
limits and 60-second runtime limits). TSan emitted its dyld module-map/backtrace warning and
reported no race failure; this qualification does not remove that diagnostic limitation.

| Invocation contract | Executed counterexample/proof |
|---|---|
| Cumulative admission | Two 4-byte sources consume exactly one shared 8-byte read quota; a ninth byte is refused before digest creation and payload reservation |
| Pre-action refusal | A 4-byte first chunk under a 2-byte read quota reaches neither digest nor owned payload; overlapping descriptor limit closes the earlier descriptor |
| Managed ownership | Source copies keep owned extents until the last copy; escaped inventory entry arrays keep result extents; created/released lease counts match |
| Copy boundary | Multi-page unaccounted copy fails; admitted copy holds 8 temporary bytes through callback and releases after normal return or throw; 7-byte capacity refuses callback entry |
| Typed failure/cleanup | Cancellation, deadline, closed control and hash quota failures preserve typed reasons and release extents; injected close failure retains typed cancellation as primary |
| Inventory | Two names plus two dot records consume four visits, without EOF visit; name/result/sort refusal cleans all resources; cancellation occurs with a live directory stream |

Evidence: `../../../../.verification/runs/pdk-source-foundation/pn20-evidence.json` and its
referenced build/runtime logs. Prior standalone Native/ASan/TSan/Core portability evidence
keeps its original scope; no new WASM or Embedded FileSystem capability is claimed.
