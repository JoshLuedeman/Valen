# Copilot Development Guide for Valen

> **Valen** is a local-first, multi-agent orchestrator written in .NET that provides offline-first AI capabilities with thin clients and a self-hosted hub. This document provides guidance for GitHub Copilot when working with this codebase.

## Project Overview

**Architecture:** Local-first orchestrator in .NET with MCP (Model Context Protocol) tools.
- **Client Profile:** `light` on MacBooks (8B model), `micro` on Raspberry Pi (3-4B model)
- **Sync Strategy:** Hub-Embeds (embeddings computed on hub, not client)
- **Snapshots:** Full VSS (Vector Similarity Search) capped for `light` profile
- **Database:** SQLite with JSON1, FTS5, and sqlite-vss extensions
- **Hub Stack:** Postgres (events) + MinIO (CAS) + Qdrant/pgvector

## Quick Start

```bash
# Prerequisites: .NET 8 SDK and Ollama installed locally

# Restore and build
dotnet restore
dotnet build -c Release

# Or using Task (recommended)
task restore && task build

# Run the orchestrator
dotnet run --project src/Orchestrator
# or: task run

# Start hub services (for sync/embedding features)
task hub-up
```

## Build Commands

| Command | Description |
|---------|-------------|
| `task restore` or `dotnet restore` | Restore NuGet packages |
| `task build` or `dotnet build -c Release` | Build the solution |
| `task run` or `dotnet run --project src/Orchestrator` | Run the orchestrator |
| `task test` or `dotnet test` | Run tests |
| `task hub-up` | Start hub services (Docker Compose) |
| `task hub-down` | Stop hub services |

## Project Structure

```
/
├── .github/          # GitHub configurations, workflows, labels
├── clients/          # (Future) Client implementations
├── docs/
│   └── adr/          # Architecture Decision Records (MADR format)
├── hub/
│   └── deploy/       # Hub deployment configs (docker-compose.yml)
├── planning/         # Project planning documents
├── scripts/          # Automation scripts (setup, GitHub integration)
├── src/
│   ├── Orchestrator/ # Main orchestrator application
│   └── Shared/       # Shared contracts and interfaces
├── Taskfile.yml      # Task runner configuration
└── Valen.sln         # Solution file
```

## Key Principles & Constraints

**Design Philosophy:**
1. **Thin clients** - Compute-intensive operations (embeddings, large models) run on the hub
2. **Offline-first** - Core functionality works without internet; sync is optional
3. **Profile-aware** - Different resource constraints for `micro`, `light`, and `standard` profiles
4. **Egress-gated** - Network calls only through explicit tool use (`hub.sync`, `web.search`)
5. **Deterministic planning** - JSON plans for transparency and reproducibility

**Key Contracts:**
- All shared interfaces and types live in `src/Shared/Interfaces.cs`
- Main interfaces: `ILlmClient`, `IEgressPolicy`, `IRagClient`
- Message format: `AgentMessage(string Role, string Content)`

**Data & Persistence:**
- SQLite with FTS5 (full-text search) and VSS (vector similarity search)
- Configuration from `appsettings.json`
- `--ephemeral` flag to disable persistence (useful for testing)

## Coding Conventions

- **Language:** C# 12 with .NET 8
- **Nullable Reference Types:** Enabled (`<Nullable>enable</Nullable>`)
- **Implicit Usings:** Enabled
- **Async/Await:** Prefer async methods for I/O operations
- **Records:** Use for data transfer objects and messages
- **Naming:** Follow standard C# conventions (PascalCase for types/methods, camelCase for parameters)

## Architecture Decision Records

All major architectural decisions are documented in `docs/adr/` following the [MADR](https://adr.github.io/madr/) format.

**Key ADRs to understand:**
- [ADR-000](../docs/adr/ADR-000-use-madr.md): Use MADR for Architecture Decision Records
- [ADR-001](../docs/adr/ADR-001-sqlite-client.md): Client DB = SQLite (JSON1, FTS5, sqlite-vss)
- [ADR-002](../docs/adr/ADR-002-hub-stack.md): Hub = Postgres + MinIO + Qdrant/pgvector
- [ADR-003](../docs/adr/ADR-003-client-profiles.md): Client Profiles (micro | light | standard)
- [ADR-004](../docs/adr/ADR-004-hub-embeds.md): Embeddings Strategy = Hub-Embeds
- [ADR-006](../docs/adr/ADR-006-egress-airlock.md): Egress Policy & Airlock

**When making architectural changes:**
1. Check existing ADRs first: `docs/adr/README.md`
2. For new decisions, create a new ADR using the template: `docs/adr/000-template.md`
3. Follow the CONTRIBUTING guide: `docs/adr/CONTRIBUTING.md`

## Testing Strategy

- Unit tests should cover core business logic
- Integration tests for database interactions
- Use `--ephemeral` flag for test isolation
- Mock `ILlmClient`, `IEgressPolicy`, and `IRagClient` interfaces for testing

## Common Development Patterns

**Adding a new tool:**
1. Define the tool interface in `src/Shared/Interfaces.cs`
2. Implement in appropriate project (Orchestrator or separate client)
3. Register with the orchestrator
4. Ensure egress policy compliance

**Working with RAG:**
- Use `IRagClient` interface for all retrieval operations
- `SearchAsync(query, topK)` for vector similarity search
- `IngestPathAsync(path)` to add documents to the knowledge base

**Egress Control:**
- All network calls must go through tools that check `IEgressPolicy`
- Policy checks: `IsAllowed(toolName, target, out reason)`
- Only approved tools (`hub.sync`, `web.search`) can access network

## Helpful Resources

- **Project Planning:** See `planning/` directory
- **Scripts:** Automation in `scripts/` (GitHub setup, project automation)
- **Hub Deployment:** `hub/deploy/docker-compose.yml`
- **Workflows:** `.github/workflows/` for CI/CD

## When in Doubt

1. **Check ADRs:** Architecture decisions are documented in `docs/adr/`
2. **Review interfaces:** Core contracts in `src/Shared/Interfaces.cs`
3. **Follow patterns:** Look at existing code in `src/Orchestrator/`
4. **Ask questions:** Open an issue or discussion for clarification
