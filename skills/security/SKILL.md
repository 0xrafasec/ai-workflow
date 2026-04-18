---
name: security
description: "Create or update docs/THREAT_MODEL.md — STRIDE-style threat model, trust boundaries, attack surface, mitigations. Use when the user asks for a threat model, security review, attack-surface analysis, STRIDE pass, or says 'what could go wrong security-wise', 'identify the threats', 'lock this down before launch', 'review the security posture'."
---
Create the threat model. Argument: $ARGUMENTS

## Context Gathering

Before interviewing, understand the system's security surface:

1. **Check for existing docs:**
   - Read `docs/THREAT_MODEL.md` — if revising, don't start from scratch
   - Read `docs/ARCHITECTURE.md` for system structure and trust boundaries
   - Read `CLAUDE.md`, `README.md`

2. **Explore the codebase for security-relevant patterns:**
   - Look for auth middleware, JWT handling, session management
   - Check for input validation patterns (or lack thereof)
   - Look for database queries (raw SQL vs ORM/parameterized)
   - Check for secrets management (env vars, config files, hardcoded values)
   - Check for exposed endpoints (route definitions, API handlers)
   - Read `docker-compose.yml` or deployment config for service exposure
   - Summarize what you found to the user — "Here's what I see from a security perspective: ..."

## Interview

Use AskUserQuestion to understand the security landscape. Adapt based on what the codebase reveals.

1. **Trust boundaries** — What is trusted? What is untrusted? Where are the boundaries?
2. **Authentication** — How do users/agents/services prove identity? What mechanisms exist today?
3. **Authorization** — Who can do what? How are permissions modeled?
4. **Sensitive data** — What data is sensitive? Credentials, PII, financial? Where does it live? How is it protected at rest and in transit?
5. **Attack surface** — What is exposed to the internet? To local users? To other services? What inputs does the system accept?
6. **Threat actors** — Who would attack this? Script kiddies, insiders, nation states? What are their capabilities?
7. **Compliance** — Any regulatory requirements? SOC2, GDPR, HIPAA, PCI?
8. **Existing security measures** — What's already in place? What's missing?

For inherited projects: "I see you're using X for auth — is that intentional or legacy? I notice Y has no input validation — is that a known gap?"

## Write

Write to `docs/THREAT_MODEL.md`:

```markdown
# Threat Model

**Version:** [version]
**Date:** [date]

## Trust Assumptions

[What is the trust model? What is trusted, what is untrusted? Include a Mermaid diagram of the trust hierarchy.]

## Security Properties

[Non-negotiable security invariants. Things that must always hold.]

- [Property 1]
- [Property 2]

## Attack Surface

| Surface | Exposure | Controls |
|---------|----------|----------|
| [surface] | [who can reach it] | [what protects it] |

## Threats

### [Threat Category 1: e.g., Agent Impersonation]

| # | Attack | Impact | Likelihood | Defense |
|---|--------|--------|------------|---------|
| 1 | [attack description] | [what happens] | [Low/Med/High] | [how it's prevented] |

### [Threat Category 2]
...

## Sensitive Data Inventory

| Data | Classification | At Rest | In Transit | Access Control |
|------|---------------|---------|------------|----------------|
| [data type] | [level] | [protection] | [protection] | [who can access] |

## Security Controls

### Implemented
- [Control 1 — what it protects against]

### Required (not yet implemented)
- [Control 1 — what it would protect against, priority]

## Compliance Requirements

[If applicable. Regulatory frameworks, what they require, current status.]
```

## After Writing

1. Present the document to the user for review. Iterate until they're satisfied.
2. Suggest next steps based on what exists:
   - No architecture doc? → "Define system structure with `/architecture`"
   - No TDD? → "Define testing and dev workflow with `/tdd`"
   - Ready to build? → "Create feature specs with `/spec <name>`, then `/roadmap`"
