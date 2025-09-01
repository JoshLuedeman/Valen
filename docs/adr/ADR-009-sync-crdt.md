# ADR-009: Event-Sourced Sync + CRDT Notes/Tasks

## Status
Accepted

## Decision
Append-only events on hub; clients replay. Content-addressed blobs (MinIO). CRDT for notes/tasks to resolve conflicts automatically.

## Consequences
- Robust multi-device convergence, offline friendly.
- Requires event schemas and snapshot builder.
