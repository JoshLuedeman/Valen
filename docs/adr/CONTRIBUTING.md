# Contributing to Valen ADRs

This guide explains how to document architectural decisions in the Valen project.

## What are ADRs?

Architecture Decision Records (ADRs) are short documents that capture important architectural decisions along with their context and consequences. We use the [MADR (Markdown Any Decision Records)](https://adr.github.io/madr/) format.

## When to write an ADR

Write an ADR when you make a decision that:
- Affects the structure, architecture, or fundamental approach of the system
- Is significant enough that future contributors should understand why it was made
- Involves trade-offs between multiple options
- Could be questioned or reversed later

Examples include:
- Choice of database or storage system
- Selection of a framework or major library
- System architecture or communication patterns
- Security or privacy policies
- Performance or scalability strategies

## How to create a new ADR

### 1. Choose a number
Look at the existing ADRs in `docs/adr/README.md` to find the next available number.

### 2. Copy the template
```bash
cp docs/adr/000-template.md docs/adr/ADR-NNN-short-title.md
```

Replace `NNN` with your number (e.g., `010`) and `short-title` with a kebab-case description (e.g., `use-graphql-api`).

### 3. Fill in the template

Follow the structure in the template:

- **Status**: Start with "Proposed"
- **Deciders**: List the people involved in making the decision
- **Date**: Use ISO 8601 format (YYYY-MM-DD)
- **Context and Problem Statement**: Explain what you're trying to solve
- **Decision Drivers**: List the factors that influenced the decision
- **Considered Options**: List all options you evaluated
- **Decision Outcome**: State which option you chose and why
- **Positive/Negative Consequences**: Document the trade-offs
- **Pros and Cons**: Detail each option's strengths and weaknesses

### 4. Keep it concise but complete

- ADRs should be readable in 5-10 minutes
- Focus on the "why" more than the "what"
- Include enough context that someone new to the project can understand the decision
- Link to external resources for detailed technical information

### 5. Update the index

Add your ADR to `docs/adr/README.md` in the appropriate position:

```markdown
- ADR-NNN: Short description — Proposed
```

### 6. Submit for review

Create a pull request with your ADR. The review process will:
- Verify the decision is documented clearly
- Ensure all options were considered
- Check that consequences are realistic
- Validate the format follows MADR conventions

## ADR Lifecycle

### Proposed
Initial state when an ADR is created for discussion.

### Accepted
The decision has been agreed upon and is now in effect.

### Superseded
A later ADR has replaced this decision. Link to the superseding ADR.

### Deprecated
The decision is no longer relevant but kept for historical context.

### Rejected
The proposal was considered but ultimately not adopted.

## Updating existing ADRs

ADRs are meant to be immutable records of decisions at a point in time. However, you can:

1. **Change status**: Update from "Proposed" to "Accepted" or "Superseded"
2. **Add follow-ups**: Document new insights or consequences discovered later
3. **Fix typos**: Minor corrections are fine
4. **Link to related ADRs**: Add references to new decisions

For significant changes to a decision, create a new ADR that supersedes the old one.

## Tips for writing good ADRs

- **Write for your future self**: Assume you'll forget the context in 6 months
- **Document alternatives**: Even if an option seems obviously wrong, explain why
- **Be honest about trade-offs**: Every decision has downsides
- **Use concrete examples**: Help readers understand the impact
- **Link to resources**: Reference RFCs, blog posts, documentation, or benchmarks
- **Keep it focused**: One decision per ADR

## Examples in this repository

See these ADRs for good examples of the format:
- [ADR-000: Use MADR](ADR-000-use-madr.md) - Meta-decision about ADR format
- [ADR-001: Client DB = SQLite](ADR-001-sqlite-client.md) - Technical decision with clear trade-offs
- [ADR-002: Hub Stack](ADR-002-hub-stack.md) - Architecture decision with multiple components

## Questions?

If you're unsure whether something needs an ADR or how to structure it, ask in your pull request or open an issue for discussion.

## References

- [MADR Homepage](https://adr.github.io/madr/)
- [MADR Template](https://github.com/adr/madr/blob/main/template/adr-template.md)
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) by Michael Nygard
- [ADR GitHub Organization](https://adr.github.io/)
