---
name: rfc
description: "Create a Request for Comments — heavier than an ADR, lighter than a full spec — for significant changes that need team input before implementation (new systems, major refactors, breaking changes, process changes). Use when the user says 'write an RFC', 'propose X to the team', 'get feedback before we build this', or the decision is too big for an ADR but premature for a spec."
---
Create a Request for Comments. Argument: $ARGUMENTS

## Context

RFCs are for significant changes that need team input before implementation — new systems, major refactors, breaking changes, process changes. Heavier than an ADR, lighter than a full spec. The goal is to get feedback, not to be exhaustive.

## Context Gathering

1. Check `docs/rfc/` for existing RFCs — determine the next number. If none exist, start at `0001`.
2. Read recent RFCs (last 2-3) to match the project's style.
3. Read `docs/ARCHITECTURE.md` and `docs/PRD.md` if they exist — the RFC should reference existing design, not repeat it.

## Interview

Use AskUserQuestion to understand the proposal deeply. Push back on vague motivation — "why now?" and "what happens if we don't do this?"

1. **Proposal** — What are you proposing? What's the elevator pitch?
2. **Motivation** — Why is this needed? What's broken, missing, or changing? What happens if we do nothing?
3. **Scope** — What does this change? What does it NOT change? Where are the boundaries?
4. **Design** — How would this work at a high level? What are the key technical decisions?
5. **Alternatives** — What other approaches were considered? Why not those?
6. **Migration** — If this changes existing behavior, how do we get from here to there? Is it backwards-compatible?
7. **Risks** — What could go wrong? What are the unknowns? What needs prototyping?
8. **Open questions** — What do you want feedback on specifically? What are you least sure about?

## Write

Write to `docs/rfc/NNNN-<slug>.md`:

```markdown
# RFC-NNNN: [Title]

**Status:** Draft | In Review | Accepted | Rejected | Withdrawn
**Author:** [who]
**Date:** [date]
**Review deadline:** [date, if applicable]

## Summary

[2-3 sentence elevator pitch. What is this and why should someone care?]

## Motivation

[Why is this needed? What problem does it solve? What happens if we don't do this?]

## Proposal

[Detailed description of the proposed change. Include diagrams (Mermaid) where they help. This should be concrete enough for someone to evaluate but not a full implementation spec.]

### Key Design Decisions

[Call out the important choices and why you made them.]

## Alternatives Considered

### [Alternative 1]
[Description, why it was rejected]

### [Alternative 2]
[Description, why it was rejected]

## Migration Plan

[If this changes existing behavior: how do we transition? Is it backwards-compatible? What's the rollback plan?]

[If greenfield: skip this section]

## Risks and Open Questions

| Item | Type | Status |
|------|------|--------|
| [concern] | Risk / Question | Open / Resolved: [answer] |

## Feedback Requested

[What specifically do you want reviewers to focus on? What are you least sure about?]

## References

- [Links to related docs, prior art, external resources]
```

## After Writing

1. Present the RFC to the user for review.
2. Suggest: "Share this with the team for feedback. Once accepted, create feature specs with `/spec <name>` for the implementation work."
