# ADR Index

> Architecture Decision Records following the [MADR](https://adr.github.io/madr/) format.
> See [CONTRIBUTING.md](CONTRIBUTING.md) for guidance on creating new ADRs.

- ADR-000: Use MADR for Architecture Decision Records — Accepted
- ADR-001: Client DB = SQLite (JSON1, FTS5, sqlite-vss) — Accepted
- ADR-002: Hub = Postgres (events) + MinIO (CAS) + Qdrant/pgvector — Accepted
- ADR-003: Client Profiles = micro | light | standard (default: light on MacBooks) — Accepted
- ADR-004: Embeddings Strategy = Hub-Embeds for all clients — Accepted
- ADR-005: Snapshot Strategy = Full VSS for `light`; metadata-only/sharded for `micro` — Accepted
- ADR-006: Egress Policy & Airlock (safelists + nonce approvals) — Accepted
- ADR-007: Optional Peer-to-Peer via MCP `peer.*` (off by default) — Proposed
- ADR-008: Offline Voice I/O + Speaker Verification — Proposed
- ADR-009: Event-Sourced Sync (append-only) + CRDT notes/tasks — Accepted
