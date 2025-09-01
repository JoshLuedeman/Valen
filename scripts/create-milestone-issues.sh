#!/usr/bin/env bash
# Bulk-create Valen issues per milestone using GitHub CLI.
# Usage: ./scripts/create-milestone-issues.sh <owner/repo>
set -euo pipefail

REPO="${1:-}"
if [[ -z "$REPO" ]]; then
  echo "Usage: $0 <owner/repo>"
  exit 1
fi

function mk() {
  local title="$1"; shift
  local body="$1"; shift
  local labels="$1"; shift
  local milestone="$1"; shift
  gh issue create --repo "$REPO" -t "$title" -b "$body" -l "$labels" -m "$milestone"
}

# Milestones must already exist (use scripts/github-setup.sh first).

############################################
# Milestone 0: Bootstrap & Policies
############################################
mk "M0: Tracking issue — Bootstrap & Policies" \
"**Goal:** Repo ready for dev; core policies & ADRs accepted.\n\n- [ ] ADRs 001–006 accepted and committed\n- [ ] CI green on main\n- [ ] Egress gate stub in place\n- [ ] Hub docker-compose starts\n- [ ] Copilot guide present\n" \
"task,adr,tooling" "Milestone 0: Bootstrap & Policies"

mk "M0: Add .editorconfig & code style" \
"**Acceptance:**\n- [ ] .editorconfig added with C# conventions\n- [ ] Warnings-as-errors enabled for Orchestrator\n" \
"tooling" "Milestone 0: Bootstrap & Policies"

mk "M0: Egress gate skeleton" \
"**Acceptance:**\n- [ ] IEgressPolicy interface\n- [ ] Default mode disabled; safelist & nonce fields\n- [ ] Unit tests for allow/deny\n" \
"client,security" "Milestone 0: Bootstrap & Policies"

mk "M0: CI build on push/PR" \
"**Acceptance:**\n- [ ] GitHub Actions builds .NET 8 projects\n- [ ] Badge in README\n" \
"tooling" "Milestone 0: Bootstrap & Policies"

mk "M0: Hub dev stack up (compose)" \
"**Acceptance:**\n- [ ] docker-compose up brings Postgres, MinIO, Qdrant, SearxNG\n- [ ] README: credentials + ports\n" \
"hub,tooling" "Milestone 0: Bootstrap & Policies"


############################################
# Milestone 1: Single-device offline Q&A
############################################
mk "M1: Tracking issue — Single-device offline Q&A" \
"**Goal:** Ingest local folder, answer offline with citations.\n\n- [ ] SQLite schema (docs, chunks, embeddings, runs)\n- [ ] RAG MCP server (search/ingest)\n- [ ] Ollama client\n- [ ] Ingest CLI\n- [ ] Ask CLI with citations\n- [ ] Unit/integration tests\n" \
"task,client,mcp" "Milestone 1: Single-device offline Q&A"

mk "M1: SQLite schema + PRAGMAs" \
"**Acceptance:**\n- [ ] Tables: documents, chunks, embeddings_vss, notes, runs\n- [ ] FTS5 virtual table for text; VSS table for vectors\n- [ ] WAL enabled; cache/tuning PRAGMAs\n" \
"client" "Milestone 1: Single-device offline Q&A"

mk "M1: RAG MCP server (local) — search & ingest" \
"**Acceptance:**\n- [ ] tools: rag.ingest(path), rag.search(query, top_k)\n- [ ] Deterministic chunking; hash-based IDs\n- [ ] Tests: ingest->search roundtrip\n" \
"client,mcp" "Milestone 1: Single-device offline Q&A"

mk "M1: Ollama ILlmClient" \
"**Acceptance:**\n- [ ] Chat completion wrapper with system+user\n- [ ] Timeout & error handling\n" \
"client" "Milestone 1: Single-device offline Q&A"

mk "M1: CLI — ingest <path>" \
"**Acceptance:**\n- [ ] Command ingests files recursively, shows stats\n- [ ] Skips duplicates via content hash\n" \
"client" "Milestone 1: Single-device offline Q&A"

mk "M1: CLI — ask \"question\" (citations)" \
"**Acceptance:**\n- [ ] Researcher queries local VSS/FTS\n- [ ] Answer includes citations (docId#chunk)\n" \
"client" "Milestone 1: Single-device offline Q&A"

mk "M1: Run log (replayable)" \
"**Acceptance:**\n- [ ] Store inputs, plan JSON, tool I/O, final text\n- [ ] Replay command re-runs with cached tool outputs\n" \
"client,tooling" "Milestone 1: Single-device offline Q&A"


############################################
# Milestone 2: Hub skeleton + Hub-Embeds
############################################
mk "M2: Tracking issue — Hub skeleton + Hub-Embeds" \
"**Goal:** Hub computes embeddings and ships snapshots. Client pulls and swaps.\n\n- [ ] Hub API (events, blobs)\n- [ ] Embedding job (bge-m3)\n- [ ] Snapshot builder (light)\n- [ ] Signature & verification\n- [ ] Client hub.sync pull & atomic swap\n" \
"task,hub,mcp" "Milestone 2: Hub skeleton + Hub-Embeds"

mk "M2: Postgres migrations — events & devices" \
"**Acceptance:**\n- [ ] events(id, type, ts, actor, payload JSONB)\n- [ ] devices(id, pubkey, profile)\n" \
"hub" "Milestone 2: Hub skeleton + Hub-Embeds"

mk "M2: MinIO CAS — put/get blobs" \
"**Acceptance:**\n- [ ] API: PUT/GET by sha256\n- [ ] Deduplication verified in tests\n" \
"hub" "Milestone 2: Hub skeleton + Hub-Embeds"

mk "M2: Embed job (bge-m3) + Qdrant ingest" \
"**Acceptance:**\n- [ ] Batch embedding from normalized chunk text\n- [ ] Push vectors to Qdrant collection with payload\n" \
"hub" "Milestone 2: Hub skeleton + Hub-Embeds"

mk "M2: Snapshot builder (light, full VSS)" \
"**Acceptance:**\n- [ ] Produce signed SQLite with metadata+VSS capped ~80k chunks\n- [ ] Publish via API; verify signature on client\n" \
"hub,client" "Milestone 2: Hub skeleton + Hub-Embeds"

mk "M2: Client hub.sync pull + atomic swap" \
"**Acceptance:**\n- [ ] Download snapshot to temp file\n- [ ] Verify signature; swap DB atomically; rollback on failure\n" \
"client,mcp" "Milestone 2: Hub skeleton + Hub-Embeds"


############################################
# Milestone 3: Egress tools & caching
############################################
mk "M3: Tracking issue — Egress tools & caching" \
"**Goal:** Safe, approved web/central search with local caching.\n\n- [ ] web.search MCP (SearxNG)\n- [ ] Readability extraction\n- [ ] Fetched cache & optional ingest\n- [ ] central.search MCP (Qdrant)\n- [ ] Planner fallback logic\n- [ ] Nonce approval flow in CLI\n" \
"task,security,hub,client" "Milestone 3: Egress tools & caching"

mk "M3: web.search (SearxNG) MCP" \
"**Acceptance:**\n- [ ] Args: query, top_k, fetch\n- [ ] Returns normalized results; optional doc texts\n" \
"mcp,hub" "Milestone 3: Egress tools & caching"

mk "M3: Readability + cache" \
"**Acceptance:**\n- [ ] HTML->text extraction with limits\n- [ ] Cache by URL hash; TTL configurable\n" \
"client" "Milestone 3: Egress tools & caching"

mk "M3: central.search (Qdrant)" \
"**Acceptance:**\n- [ ] Query central ANN with filters\n- [ ] Respect egress gate; return doc refs\n" \
"hub,mcp" "Milestone 3: Egress tools & caching"

mk "M3: Planner escalation policy" \
"**Acceptance:**\n- [ ] If local recall low, propose hub.sync delta then web\n- [ ] Tests for decision thresholds\n" \
"client" "Milestone 3: Egress tools & caching"

mk "M3: CLI nonce approval UX" \
"**Acceptance:**\n- [ ] Show nonce; require `approve <nonce>` before gated tool\n- [ ] Logs include approval event\n" \
"security,client" "Milestone 3: Egress tools & caching"


############################################
# Milestone 4: PA/Ops + Coder
############################################
mk "M4: Tracking issue — PA/Ops + Coder" \
"**Goal:** Notes/tasks (CRDT), shell/git/fs tools, code patch & test loop.\n\n- [ ] notes.* (CRDT)\n- [ ] tasks.*\n- [ ] fs sandbox + confirm-before-write\n- [ ] shell.run allowlist\n- [ ] git wrappers\n- [ ] code.run & tests.run\n- [ ] Coder patch+diff flow\n" \
"task,client,mcp" "Milestone 4: PA/Ops + Coder"

mk "M4: notes.* (CRDT)" \
"**Acceptance:**\n- [ ] Create/append/edit CRDT docs\n- [ ] Merge test across two simulated devices\n" \
"client,mcp" "Milestone 4: PA/Ops + Coder"

mk "M4: tasks.* CRUD" \
"**Acceptance:**\n- [ ] Create/list/update/complete tasks\n- [ ] Stored in SQLite; optional sync event\n" \
"client,mcp" "Milestone 4: PA/Ops + Coder"

mk "M4: fs sandbox + confirm-before-write" \
"**Acceptance:**\n- [ ] Writes restricted to workspace dir\n- [ ] Confirm token required for writes outside\n" \
"security,client" "Milestone 4: PA/Ops + Coder"

mk "M4: shell.run allowlist" \
"**Acceptance:**\n- [ ] Only allowlisted commands\n- [ ] Timeout & output size caps\n" \
"security,client" "Milestone 4: PA/Ops + Coder"

mk "M4: git wrappers" \
"**Acceptance:**\n- [ ] git.status, git.diff, git.commit\n- [ ] Tests using temp repo\n" \
"client,mcp" "Milestone 4: PA/Ops + Coder"

mk "M4: code.run & tests.run" \
"**Acceptance:**\n- [ ] Run dotnet/npm tasks in workspace\n- [ ] Surface exit codes & logs to model\n" \
"client,mcp" "Milestone 4: PA/Ops + Coder"

mk "M4: Coder patch+diff loop" \
"**Acceptance:**\n- [ ] Agent proposes patch; write to workspace; run tests; present diff\n- [ ] Human confirm for final write outside workspace\n" \
"client" "Milestone 4: PA/Ops + Coder"


############################################
# Optional: Voice I/O + Speaker Verification
############################################
mk "V1: Tracking issue — Voice I/O + Speaker Verification" \
"**Goal:** Offline STT/TTS + speaker verify gated by wake-word.\n\n- [ ] faster-whisper wrapper\n- [ ] Piper TTS MCP\n- [ ] ECAPA speaker verification\n- [ ] Enrollment + encrypted voiceprints\n- [ ] Planner integration for sensitive ops\n" \
"voice,mcp" "Optional: Voice I/O + Speaker Verification"

mk "V1: faster-whisper MCP wrapper" \
"**Acceptance:**\n- [ ] voice.listen start/stop\n- [ ] Streams transcripts\n" \
"voice,mcp" "Optional: Voice I/O + Speaker Verification"

mk "V1: Piper TTS MCP" \
"**Acceptance:**\n- [ ] voice.speak(text)\n- [ ] Select voice via config\n" \
"voice,mcp" "Optional: Voice I/O + Speaker Verification"

mk "V1: ECAPA speaker verification" \
"**Acceptance:**\n- [ ] Enroll 3–5 samples\n- [ ] Verify cosine-sim gate\n" \
"voice,security" "Optional: Voice I/O + Speaker Verification"

mk "V1: Enrollment UX + encryption" \
"**Acceptance:**\n- [ ] Encrypt voiceprints at rest\n- [ ] CLI to enroll/reset\n" \
"voice,security" "Optional: Voice I/O + Speaker Verification"

mk "V1: Planner integration gates" \
"**Acceptance:**\n- [ ] Require verify before sensitive commands (configurable)\n" \
"voice,client" "Optional: Voice I/O + Speaker Verification"
