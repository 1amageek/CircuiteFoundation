# CircuiteFoundation Agent Guide

This package is the dependency floor for the LSI workspace.

## Admission rule

Add a public type only when multiple design domains exchange it with identical semantics, Swift does not already
provide it, and it has no dependency on a domain engine or orchestration layer.

## Boundaries

- Keep domain algorithms and domain results in their owning packages.
- Keep flow stages, policy, resume, qualification, and approval outside this package.
- Use Swift capabilities directly for cancellation, streams, time, and serialization. Add a custom identity only
  when cross-process domain separation and canonical wire encoding cannot be expressed safely by a generic Swift
  identity.
- Keep database storage, transactions, queries, indexes, WAL, and OpenDB objects outside this package.
- Keep database-facing Foundation values limited to identity, reference, schema, capability, artifact, provenance,
  and diagnostic contracts shared by multiple consumers.
- Keep the portable Core target separate from Crypto and FileSystem implementation targets; do not make domain
  targets acquire implementation dependencies transitively.
- Do not add a universal request or result envelope.
- Keep one primary type per Swift file.
- Use typed errors and never use `try?`.
