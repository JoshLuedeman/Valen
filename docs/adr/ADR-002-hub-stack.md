# ADR-002: Hub = Postgres + MinIO (CAS) + Qdrant/pgvector

## Status
Accepted

## Context
Hub has no size/efficiency constraints; must support multi-device sync, blob CAS, and central ANN.

## Decision
- Postgres for append-only events & device metadata.
- MinIO (S3) for content-addressed blobs (SHA-256).
- Qdrant (preferred) or Postgres+pgvector for vectors.

## Consequences
### Positive
- Boring, reliable infra; scales independently.
### Negative
- More moving parts than a single DB.
### Follow-ups
- Sign snapshots; manage migrations under `hub/migrations`.
