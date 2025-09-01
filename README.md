# Valen (Local-First Multi-Agent)

Thin clients (MacBook = `light` profile; Raspberry Pi = `micro`) + a beefy self-hosted hub.
Offline-first, polyglot tools via MCP, with **Hub-Embeds** and signed **profile-aware snapshots**.

## Quickstart (walking skeleton)
```bash
# 1) Install .NET 8 and Ollama locally
# 2) Restore & build
task restore && task build

# 3) Run orchestrator skeleton
task run

# 4) (Optional) Start hub services for later milestones
task hub-up
```
See `docs/adr/README.md` for accepted decisions and `hub/deploy/docker-compose.yml` for hub services.

> Valen — your offline-first, multi-agent companion (light profile on MacBooks, Hub-Embeds).
