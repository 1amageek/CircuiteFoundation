# CircuiteFoundation

`CircuiteFoundation` is the dependency floor shared by independently usable circuit-design engines,
`DesignDatabase`, external services, and Xcircuite composition. It defines stable cross-domain values and contracts
without owning database storage, a design flow, a project model, or any domain algorithm.

```mermaid
flowchart BT
  Swift["Swift Standard Library and Foundation"]
  Common["CircuiteFoundation"]
  Database["DesignDatabase"]
  Engines["Independent design engines"]
  Flow["DesignFlowKernel"]
  Umbrella["Xcircuite umbrella"]

  Common --> Swift
  Database --> Common
  Engines --> Common
  Flow --> Common
  Umbrella --> Engines
  Umbrella --> Flow
```

Arrows represent compile-time dependency from consumer to dependency.

## What belongs here

| Area | Public surface |
|---|---|
| Engine execution | Minimal `Engine` protocol |
| Artifact trust | Location, role, identity, format, digest, reference, verification |
| Evidence | Invocation, environment fingerprint, execution provenance, and evidence manifest |
| Diagnostics | Stable severity, code, subject, and suggested action |
| Design addressing | Database, revision, entity, path, external-object references |
| Physical representation | Database-unit scale and electrical quantities absent from Foundation |
| Compatibility | Schema version ranges and capability negotiation values |

Domain results remain in their owning packages. A timing engine owns timing paths, a DRC engine owns violations,
and a PDK package owns process rules. `DesignDatabase` owns storage, revision, transaction, and query behavior.
Xcircuite owns composition and orchestration.

Artifact roles are open validated tokens and every artifact locator requires an
explicit role. In-process and external-process invocations share one typed
provenance model without persisting raw environment variables or secrets.
Evidence manifests carry an explicit schema version; missing schema metadata is
rejected rather than inferred.

## Usage

```swift
import CircuiteFoundation

struct SimulationEngine: Engine {
    func execute(_ request: SimulationRequest) async throws -> SimulationOutput {
        // Domain implementation
    }
}
```

The database-facing identity, exact reference, schema range, capability negotiation, typed diagnostic subject,
and typed provenance revision contracts are implemented as an intentionally breaking API. Crypto/filesystem
target separation and location-independent artifact availability remain open work. See `DESIGN.md`,
`REQUIREMENTS.md`, and `GOAL_STATUS.md` for the exact boundary.
