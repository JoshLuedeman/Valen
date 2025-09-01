# ADR-007: Optional Peer-to-Peer via MCP `peer.*`

## Status
Proposed

## Context
Sometimes users want device-to-device actions (handoff, remote exec, beaming files).

## Decision
Introduce `peer.*` tools using WebRTC with hub-provided signaling (and TURN if needed), E2E encrypted, off by default.

## Consequences
- Flexible, local-first workflows when hub unreachable.
- Added complexity and security surface; keep gated.
