# ADR-005: Snapshot Strategy

## Status
Accepted

## Context
Need fast local retrieval on thin clients with bounded disk/RAM.

## Decision
- `light` profile pulls **Full VSS** snapshot capped (e.g., 80k chunks).
- `micro` may pull **Metadata-only** or **Sharded** snapshots.

## Pros/Cons
### Full VSS
+ Instant search, best quality, low client CPU
- Larger download size; build time on hub

### Metadata-only
+ Very small; trivial to ship often
- Keyword-only offline search; lower quality

### Sharded
+ Pull only relevant domains/recency; smaller deltas
- More orchestration (shard selection logic)

## Recommendation
Default to Full VSS for `light`; support sharded channels for opt-in domains (e.g., Work, Personal, Recent).
