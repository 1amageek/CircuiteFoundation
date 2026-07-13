# CircuiteFoundation Agent Guide

This package is the dependency floor for the LSI workspace.

## Admission rule

Add a public type only when multiple design domains exchange it with identical semantics, Swift does not already
provide it, and it has no dependency on a domain engine or orchestration layer.

## Boundaries

- Keep domain algorithms and domain results in their owning packages.
- Keep flow stages, policy, resume, qualification, and approval outside this package.
- Use Swift capabilities directly for cancellation, streams, time, serialization, and identity.
- Do not add a universal request or result envelope.
- Keep one primary type per Swift file.
- Use typed errors and never use `try?`.
