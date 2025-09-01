# ADR-008: Offline Voice I/O + Speaker Verification

## Status
Proposed

## Context
Enable voice UX and user verification without cloud dependencies.

## Decision
Use faster-whisper (STT), Piper (TTS), and ECAPA-based speaker verification, all offline, as an optional MCP server.

## Consequences
- Low overhead when wake-word gated.
- Stores encrypted voiceprints locally.
