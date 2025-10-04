# ADR-000: Use MADR for Architecture Decision Records

## Status
Accepted

## Context
The project needs a standardized way to document architectural decisions that is:
- Simple and accessible (Markdown-based)
- Well-structured for long-term maintainability
- Compatible with common ADR tooling
- Easy for contributors to use

MADR (Markdown Any Decision Records) is a lean template for capturing decisions, with wide adoption in the open-source community and good tooling support.

## Decision
Adopt the MADR 3.0.0 template format for all architectural decision records in this repository.

All ADRs will:
- Be stored in `docs/adr/`
- Use the naming convention `ADR-NNN-short-title.md`
- Follow the MADR template structure
- Be indexed in `docs/adr/README.md`

## Options Considered

### Option 1: Custom minimal format
+ Very lightweight, no overhead
- Risk of inconsistency over time
- No tooling support

### Option 2: MADR (Markdown Any Decision Records)
+ Well-established, widely adopted format
+ Good balance of structure and simplicity
+ Compatible with adr-tools and other utilities
- Slightly more verbose than absolute minimum

### Option 3: Heavyweight formats (ADR templates with extensive sections)
+ Very thorough documentation
- Too much overhead for rapid iteration
- Discourages documenting smaller decisions

## Consequences

### Positive
- Consistent structure across all ADRs improves discoverability
- New contributors have clear guidance on documenting decisions
- Compatible with common ADR tooling (adr-tools, adr-viewer, etc.)
- Lightweight enough to encourage documentation of decisions

### Negative
- Requires discipline to maintain consistency
- May need to retroactively update existing ADRs for full compliance

### Follow-ups
- Add CONTRIBUTING guide with ADR process documentation
- Create scripts/helpers for generating new ADRs from template
- Consider adding adr-tools for command-line ADR management

## References
- [MADR Homepage](https://adr.github.io/madr/)
- [MADR Template](https://github.com/adr/madr/blob/main/template/adr-template.md)
- [Documenting Architecture Decisions by Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
