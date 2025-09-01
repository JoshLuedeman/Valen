# ADR-006: Egress Policy & Airlock

## Status
Accepted

## Decision
No network egress by default. Safelists + nonce approvals for `web.search`, `central.search`, `hub.sync`.

## Consequences
- Prevents accidental data exfiltration.
- Requires explicit user approval.
