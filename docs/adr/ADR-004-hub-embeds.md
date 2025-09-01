# ADR-004: Embeddings Strategy = Hub-Embeds

## Status
Accepted

## Context
Minimize client compute & battery; keep indexing quality high.

## Decision
Compute embeddings and ANN indexes on the hub, ship profile-aware snapshots to clients.

## Consequences
- Fast local retrieval; low client CPU.
- Requires snapshot pipeline & signing.
