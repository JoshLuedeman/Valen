# Copilot Development Guide for Valen

**Architecture summary:** Local-first orchestrator in .NET with MCP tools.
Client profile = `light` on MacBooks. Sync strategy = Hub-Embeds. Snapshots = Full VSS (capped).

**Key contracts live in `src/Shared`**. Prefer generating code that:
- Keeps the client thin; embeddings are not computed on client.
- Uses SQLite + FTS5 + VSS via a local RAG server.
- Obeys the egress gate (no network calls unless the `hub.sync` or `web.search` tool is explicitly used).
- Produces deterministic JSON plans for Planner and tool calls.
- Uses config from `appsettings.json` and supports `--ephemeral` flag to disable persistence.

When in doubt, align with ADRs in `docs/adr`.
