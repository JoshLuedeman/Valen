# ADR-001: Client DB = SQLite (JSON1, FTS5, sqlite-vss)

## Status
Accepted

## Context
Clients must be thin, offline-first (MacBook `light`, RPi `micro`). Need local store for docs, notes, embeddings, and fast retrieval without daemons.

## Decision
Use SQLite with JSON1, FTS5, and sqlite-vss on clients.

## Options Considered
- DuckDB (great analytics, weaker OLTP & ANN)
- RocksDB/LMDB (KV only, missing SQL/FTS/ANN)
- LiteDB (.NET native, smaller ecosystem, no ANN)

## Consequences
### Positive
- Embedded, portable, ACID; no services to run.
- Strong FTS and local ANN via sqlite-vss.
### Negative
- Limited concurrent writers; avoid syncing raw .db across devices.
### Follow-ups
- Use snapshots and event replay, not DB file sync.
