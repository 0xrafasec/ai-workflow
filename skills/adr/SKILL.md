---
name: adr
description: "Create an Architecture Decision Record (ADR) — a single numbered file capturing context, options, and the choice made. Use whenever the user wants to document a design decision, says 'record why we picked X', 'write an ADR', 'lock in this choice', or is choosing between technical options worth preserving for future contributors. Invoked as /adr <title>."
---
Create an Architecture Decision Record. Argument: $ARGUMENTS

## Context

ADRs capture a single decision — the context, options considered, and the choice made. They're lightweight and accumulate over time. Each ADR is a separate numbered file.

## Context Gathering

1. Check `docs/adr/` for existing ADRs — determine the next number. If no ADRs exist, start at `0001`.
2. Read recent ADRs (last 2-3) to match the project's style and voice.
3. If the decision relates to architecture, read `docs/specs/ARCHITECTURE.md` for context.

## Interview

Use AskUserQuestion to extract the decision. Keep it focused — an ADR is one decision, not a design doc.

1. **What's the decision?** — What are you deciding? What triggered this decision?
2. **Context** — What constraints, requirements, or pressures led to this? What's the current state?
3. **Options considered** — What alternatives did you evaluate? What are the tradeoffs of each?
4. **Decision** — What did you choose and why? What was the deciding factor?
5. **Consequences** — What changes as a result? What are the known downsides you're accepting?

If the decision is straightforward (user already knows what they want and why), keep the interview to 1-2 questions to fill in gaps.

## Write

Write to `docs/adr/NNNN-<slug>.md`:

```markdown
# ADR-NNNN: [Title]

**Status:** Proposed | Accepted | Deprecated | Superseded by [ADR-XXXX]
**Date:** [date]
**Deciders:** [who was involved]

## Context

[What is the issue? What forces are at play? What constraints exist?]

## Decision

[What was decided. State it clearly in one sentence, then elaborate if needed.]

## Options Considered

### Option A: [Name]
- **Pros:** [benefits]
- **Cons:** [drawbacks]

### Option B: [Name]
- **Pros:** [benefits]
- **Cons:** [drawbacks]

### Option C: [Name] (if applicable)
- **Pros:** [benefits]
- **Cons:** [drawbacks]

## Consequences

### Positive
- [What improves]

### Negative
- [What gets harder or what risks are accepted]

### Neutral
- [What changes without clear positive/negative valence]

## Related

- [Links to related ADRs, specs, issues, or documents]
```

## After Writing

1. Present the ADR to the user for review.
2. Ask if the status should be "Proposed" (needs team review) or "Accepted" (decided).
