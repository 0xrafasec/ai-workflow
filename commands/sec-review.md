# Security Review

You are a senior security engineer conducting a security review. Argument: `$ARGUMENTS`

---

## 1. Determine Mode and Branch

Parse the argument to determine the review mode and target branch:

- **No argument or `diff`**: Diff mode against `main`
- **`diff <branch>`**: Diff mode against the specified `<branch>`
- **`full`**: Full codebase scan (all source files, no diff)
- **`full <path>`**: Full scan scoped to a specific directory

### Diff Mode Setup

Run these commands to gather the diff context:

```
git status
git log --oneline <base-branch>..HEAD
git diff <base-branch>...HEAD
```

If the diff is empty (e.g., on the base branch itself), inform the user and suggest using `full` mode instead.

### Full Mode Setup

Explore the codebase structure and identify all source files (excluding `node_modules`, `dist`, `.git`, lock files, and generated files).

---

## 2. Launch Parallel Analysis Agents

Spawn **parallel sub-agents** (using the Agent tool) to analyze different security categories concurrently. Each agent receives the relevant file list or diff and its assigned category.

### Agent 1: Injection & Input Validation
- SQL injection, NoSQL injection, command injection, XXE, template injection
- Path traversal in file operations
- Unsafe deserialization (pickle, YAML, JSON with type coercion)
- `eval()`, `new Function()`, `exec()`, `spawn()` with untrusted input
- Prototype pollution

### Agent 2: Authentication, Authorization & Crypto
- Authentication bypass or logic flaws
- Privilege escalation paths
- Session management issues
- JWT vulnerabilities (algorithm confusion, missing validation)
- Hardcoded API keys, passwords, tokens, or secrets in source code
- Weak cryptographic algorithms or misuse
- Missing timing-safe comparisons for secret comparison
- Certificate validation bypasses

### Agent 3: Data Exposure & Web Security
- Sensitive data logging (secrets, PII, tokens — NOT urls or generic metadata)
- API endpoint data leakage
- Debug information exposure in production paths
- XSS via `dangerouslySetInnerHTML`, `bypassSecurityTrustHtml`, or similar unsafe methods
- SSRF where attacker controls host/protocol (path-only is excluded)
- Open redirects with concrete exploit path

### Agent 4: Configuration & Supply Chain
- GitHub Actions workflows with untrusted input injection (PR title/body in `run:` blocks)
- Misconfigured permissions in CI/CD
- Dependencies with known critical vulnerabilities (only if obvious from package.json)
- Insecure default configurations
- Missing security headers or CORS misconfigurations (only if server code exists)

**Each agent MUST:**
- Read every relevant file, not just scan filenames
- Trace data flow from inputs to sensitive operations
- Assign a confidence score (1-10) to each finding
- Only report findings with confidence >= 8
- Only report HIGH or MEDIUM severity

---

## 3. Hard Exclusions (Instruct Every Agent)

Each agent MUST automatically exclude these finding types — do NOT report them:

1. Denial of Service (DOS), resource exhaustion, or rate limiting issues
2. Secrets stored on disk if otherwise secured (e.g., `.env` files in `.gitignore`)
3. Memory/CPU exhaustion or resource management leaks
4. Input validation on non-security-critical fields without proven exploit path
5. GitHub Actions issues unless clearly triggerable via untrusted input
6. Lack of hardening measures without a concrete vulnerability
7. Theoretical race conditions without a practical exploit
8. Outdated third-party library versions (managed separately)
9. Memory safety issues in memory-safe languages (Rust, Go, JS/TS, Java, Python, etc.)
10. Findings only in test files or test utilities
11. Log spoofing or logging unsanitized non-secret data
12. SSRF that only controls the URL path (not host/protocol)
13. User-controlled content in AI prompts
14. Regex injection or regex DOS
15. Issues in documentation or markdown files
16. Lack of audit logs
17. Client-side permission/auth checks (server is responsible)
18. Environment variables and CLI flags (trusted values)
19. React/Angular components without explicit unsafe methods (`dangerouslySetInnerHTML`, etc.)
20. Subtle web vulns (tabnabbing, XS-Leaks) unless extremely high confidence

### Precedents

- Logging high-value secrets (API keys, tokens, passwords) in plaintext IS a vulnerability
- Logging URLs is assumed safe
- UUIDs are unguessable — no validation needed
- Command injection in shell scripts only valid if untrusted input has a concrete path in

---

## 4. Consolidate & Filter

After all agents complete:

1. Collect all findings from all agents
2. Remove duplicates
3. Remove any finding with confidence < 8
4. Remove any finding matching the hard exclusions above
5. Sort by severity (HIGH first, then MEDIUM)

---

## 5. Output Format

Produce the final report in this exact structure:

### Header

```markdown
# Security Review Report

**Mode:** [Diff against `<branch>` | Full codebase scan]
**Date:** YYYY-MM-DD
**Branch:** <current-branch>
**Commit:** <short-hash>
```

### Verdict Section

```markdown
## Verdict: [PASS | REVIEW | FAIL]

| Metric | Value |
|--------|-------|
| Files reviewed | N |
| HIGH findings | N |
| MEDIUM findings | N |
```

- **PASS**: Zero findings
- **REVIEW**: Only MEDIUM findings
- **FAIL**: Any HIGH finding

### Findings Section (only if findings exist)

For each finding, use this compact format:

```markdown
## [N]. [Category]: `file/path.ts:line`

- **Severity:** HIGH | MEDIUM
- **Description:** One-line explanation of the vulnerability
- **Fix:**

\`\`\`typescript
// Before (vulnerable)
<vulnerable code>

// After (fixed)
<fixed code>
\`\`\`
```

### Positive Practices Section

Always include a simple bulleted list of security practices done correctly. One line each, no elaboration:

```markdown
## Positive Practices

- Timing-safe comparison for webhook signatures
- OAuth tokens not exposed on public config
- Input encoding on query parameters
- ...
```

---

## 6. Final Instructions

- Do NOT create or modify any files — this is a read-only review
- Do NOT run tests or build commands
- Be concise — the user wants actionable fixes, not essays
- If zero findings: still output the full report structure with PASS verdict and the positive practices list
- If in diff mode with no changes: tell the user "No changes to review" and suggest `/sec-review full`
