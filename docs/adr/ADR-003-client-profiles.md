# ADR-003: Client Profiles (micro | light | standard)

## Status
Accepted

## Context
Different devices have different resources; we want thin clients.

## Decision
Default MacBook profile = `light` (8B model, VSS capped, Hub-Embeds). RPi = `micro` (3–4B model, FTS-first).

## Consequences
- Consistent UX; predictable resource use.
- Planner considers profile for retrieval strategy.
