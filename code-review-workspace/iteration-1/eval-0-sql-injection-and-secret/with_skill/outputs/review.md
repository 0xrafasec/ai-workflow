# Code Review Report

**Stack:** Node.js / TypeScript — Express 4, `pg` (node-postgres), native `fetch`
**Mode:** Full scan
**Branch:** 004-web-shell-mvp
**Date:** 2026-04-15

> **Note on parallel agents:** The `Agent` tool (for spawning nested subagents) is not available in this execution environment. The three review passes (Security, Architecture, Stack-Specific) were executed inline sequentially by the reviewer. Their raw outputs are reproduced as appendices below and then merged and deduplicated in the consolidated report.

---

## Verdict: FAIL

| Metric | Value |
|--------|-------|
| Files reviewed | 1 (`server.ts`) |
| Security findings | 5 (2 HIGH, 3 MEDIUM) |
| Architecture findings | 5 (1 HIGH, 3 MEDIUM, 1 LOW) |  
| Stack-specific findings | 4 (0 HIGH, 2 MEDIUM, 2 LOW) — after deduplication |
| **Total unique findings** | **12 (3 HIGH, 6 MEDIUM, 3 LOW)** |

---

## Security Findings

### S1. SQL Injection: `server.ts:15-16`
- **Severity:** HIGH
- **Confidence:** 10/10
- **Description:** `req.query.name` is interpolated directly into a SQL template literal, enabling full SQL injection.
- **Criterion violated:** TypeScript guide → "Template literal SQL — is SQL injection. Use parameterized queries."
- **Fix:**
  ```typescript
  // Before (vulnerable)
  const result = await pool.query(
    `SELECT id, email, name FROM users WHERE name LIKE '%${name}%'`,
  );

  // After (fixed) — parameterized query
  const result = await pool.query(
    "SELECT id, email, name FROM users WHERE name LIKE $1",
    [`%${name}%`],
  );
  ```

### S2. Hardcoded Live Stripe API Key: `server.ts:4`
- **Severity:** HIGH
- **Confidence:** 10/10
- **Description:** A live production Stripe secret key (`sk_live_...`) is hardcoded in source. The `sk_live_` prefix confirms this is not a test key and has real financial impact if exposed via version control.
- **Criterion violated:** TypeScript guide → "Hardcoded secrets in source — API keys, tokens in source files. Must come from environment."
- **Fix:**
  ```typescript
  // Before (vulnerable)
  const STRIPE_API_KEY = "sk_live_EXAMPLE_PLANTED_FIXTURE_NOT_A_REAL_KEY";

  // After (fixed)
  const STRIPE_API_KEY = process.env.STRIPE_API_KEY;
  if (!STRIPE_API_KEY) throw new Error("STRIPE_API_KEY env var is required");
  ```
  Additionally: rotate the exposed key immediately in the Stripe dashboard.

### S3. Data Exposure — `SELECT *` on User Record: `server.ts:35-36`
- **Severity:** MEDIUM
- **Confidence:** 8/10
- **Description:** `SELECT * FROM users WHERE id = $1` may return password hashes, tokens, or other sensitive columns that are then forwarded verbatim to the caller via `res.json(result.rows[0])`. No field allowlisting is applied.
- **Fix:**
  ```typescript
  // Before (exposes all columns)
  const result = await pool.query("SELECT * FROM users WHERE id = $1", [id]);
  res.json(result.rows[0]);

  // After (explicit column allowlist)
  const result = await pool.query(
    "SELECT id, name, email, created_at FROM users WHERE id = $1",
    [id],
  );
  res.json(result.rows[0] ?? null);
  ```

### S4. Missing Input Validation on `/charge` — Unvalidated `amount` and `token`: `server.ts:22-32`
- **Severity:** MEDIUM
- **Confidence:** 9/10
- **Description:** `amount` and `token` from `req.body` are passed to the Stripe API without any type, range, or format validation. An attacker may supply `amount: 0`, negative values, or inject unexpected types.
- **Criterion violated:** TypeScript guide → "Zod/Joi at boundaries — external data (user input) must be runtime-validated, not just typed."
- **Fix:**
  ```typescript
  import { z } from "zod";

  const ChargeBody = z.object({
    amount: z.number().int().positive().max(999999),
    token: z.string().regex(/^tok_/),
  });

  app.post("/charge", async (req, res, next) => {
    const parsed = ChargeBody.safeParse(req.body);
    if (!parsed.success) return res.status(400).json(parsed.error);
    const { amount, token } = parsed.data;
    // ... proceed
  });
  ```

### S5. Stripe API Response Proxied Verbatim: `server.ts:31`
- **Severity:** MEDIUM
- **Confidence:** 8/10
- **Description:** `res.json(await response.json())` forwards the raw Stripe API response to the client, which may include card fingerprints, risk metadata, internal Stripe error codes, or sensitive billing details.
- **Fix:** Extract only the fields the client needs (e.g., `{ id, status, amount }`) and return those; map Stripe error responses to sanitized client-facing messages.

---

## Architecture Findings

### A1. Unhandled Async Errors in All Route Handlers: `server.ts:13, 21, 34`
- **Severity:** HIGH
- **Issue:** All three `async` route handlers have no `try/catch` and no `next(err)` pass-through. Any unhandled rejection (DB error, network failure) will leave the request hanging in Express 4 and will crash the process in Node.js 15+ due to unhandled promise rejection.
- **Criterion violated:** TypeScript guide → "Error handling middleware — Express/Fastify need a centralized error handler." / "Unhandled promise rejections."
- **Suggestion:**
  ```typescript
  // Option A: wrap each handler
  app.get("/users/search", async (req, res, next) => {
    try {
      // ...
    } catch (err) {
      next(err);
    }
  });

  // Option B (preferred): use express-async-errors or upgrade to Express 5
  import "express-async-errors";
  // Then add a centralized error handler:
  app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  });
  ```

### A2. No Input Validation at Route Boundaries: `server.ts:14, 22-23`
- **Severity:** MEDIUM
- **Issue:** `req.query.name` is typed by Express as `string | ParsedQs | string[] | ParsedQs[] | undefined`. Using it in a template literal without narrowing is a TypeScript error and a runtime hazard. No schema validation exists anywhere.
- **Criterion violated:** TypeScript guide → "Zod/Joi at boundaries."
- **Suggestion:** Add a Zod schema validation step at the top of each handler for all `req.body`, `req.query`, and `req.params` inputs.

### A3. No Graceful Shutdown: `server.ts:40`
- **Severity:** MEDIUM
- **Issue:** `app.listen(3000)` with no SIGTERM/SIGINT handler. On container stop or deployment, the pg connection pool will not be drained and in-flight requests will be killed.
- **Criterion violated:** TypeScript guide → "Graceful shutdown — handle SIGTERM/SIGINT. Close database connections."
- **Suggestion:**
  ```typescript
  const server = app.listen(PORT);

  const shutdown = async () => {
    server.close(async () => {
      await pool.end();
      process.exit(0);
    });
  };
  process.on("SIGTERM", shutdown);
  process.on("SIGINT", shutdown);
  ```

### A4. No Environment Config Validation at Startup: `server.ts:5-7`
- **Severity:** MEDIUM
- **Issue:** `DATABASE_URL` is consumed without validation. If unset, `Pool` receives `connectionString: undefined` and will fail at query time with an opaque error rather than at startup with a clear message.
- **Criterion violated:** TypeScript guide → "Environment configuration — validate all env vars at startup (with Zod), fail fast on missing config."
- **Suggestion:**
  ```typescript
  import { z } from "zod";
  const env = z.object({
    DATABASE_URL: z.string().url(),
    STRIPE_API_KEY: z.string().startsWith("sk_"),
    PORT: z.coerce.number().default(3000),
  }).parse(process.env);
  ```

### A5. Database Pool Constructed at Module Top-Level (Side Effect on Import): `server.ts:5-7`
- **Severity:** LOW
- **Issue:** `new Pool(...)` at module scope establishes a DB connection at `require()` time, making the module impossible to test without a live database and violating "no side effects on import."
- **Criterion violated:** TypeScript guide → "Side effects on import — database connections at module level make testing hard."
- **Suggestion:** Wrap the pool construction and `app.listen` in an exported `start()` function, allowing test code to import handlers without triggering connections.

---

## Stack-Specific Findings

### P1. `req.query.name` Used as String Without Type Narrowing: `server.ts:14`
- **Severity:** MEDIUM
- **Issue:** `req.query.name` is `string | ParsedQs | string[] | ParsedQs[] | undefined` in Express typings. Interpolating it directly would be a `TS2345` compile error and at runtime could stringify as `[object Object]` or `undefined`, producing a malformed SQL `LIKE` clause.
- **Suggestion:**
  ```typescript
  const { name } = req.query;
  if (typeof name !== "string" || !name.trim()) {
    return res.status(400).json({ error: "name must be a non-empty string" });
  }
  ```

### P2. `parseInt` Result Not Validated for `NaN`: `server.ts:35`
- **Severity:** LOW
- **Issue:** `parseInt('abc', 10)` returns `NaN`. Passing `NaN` to a pg parameterized query causes a runtime error. Should check `Number.isInteger(id)` after parsing.
- **Suggestion:**
  ```typescript
  const id = parseInt(req.params.id, 10);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ error: "Invalid id" });
  }
  ```

### P3. No CORS Configuration: `server.ts:10-11`
- **Severity:** MEDIUM
- **Issue:** No `cors()` middleware is set. Without it, either all cross-origin requests succeed (permissive default) or browser clients are silently blocked. An explicit CORS policy is required for any API consumed from a browser.
- **Suggestion:**
  ```typescript
  import cors from "cors";
  app.use(cors({
    origin: process.env.ALLOWED_ORIGIN ?? "http://localhost:3001",
    methods: ["GET", "POST"],
  }));
  ```

### P4. Hardcoded Port 3000: `server.ts:40`
- **Severity:** LOW
- **Issue:** Port is hardcoded. Should be read from `process.env.PORT` to allow deployment configuration.
- **Suggestion:**
  ```typescript
  const PORT = Number(process.env.PORT) || 3000;
  app.listen(PORT, () => console.log(`Listening on port ${PORT}`));
  ```

---

## Positive Practices

- **Parameterized query on `/users/:id`** (`server.ts:36`): The `GET /users/:id` route uses a proper parameterized query (`$1`) with the pg driver — the correct approach, which prevents SQL injection on that endpoint.
- **`express.json()` middleware**: JSON body parsing is correctly configured before route definitions.
- **`DATABASE_URL` via environment**: The database connection string is correctly read from the environment (the pattern is right, just needs validation).
- **Consistent async/await style**: All handlers use `async/await` rather than mixing callbacks and promises.

---

## Appendix A — Raw Security Review Pass (Agent 1 inline output)

### 1. SQL Injection: `server.ts:15-16`
- **Severity:** HIGH
- **Confidence:** 10/10
- **Description:** User-controlled `req.query.name` interpolated into SQL template literal. Classic SQL injection enabling full DB read/write.
- **Fix:**
  ```typescript
  // Before (vulnerable)
  `SELECT id, email, name FROM users WHERE name LIKE '%${name}%'`
  // After (fixed)
  "SELECT id, email, name FROM users WHERE name LIKE $1", [`%${name}%`]
  ```

### 2. Hardcoded Live Stripe Secret Key: `server.ts:4`
- **Severity:** HIGH
- **Confidence:** 10/10
- **Description:** `sk_live_EXAMPLE_PLANTED_FIXTURE_NOT_A_REAL_KEY` — live production Stripe secret committed in source. Immediate credential rotation required.
- **Fix:** Move to `process.env.STRIPE_API_KEY`; rotate the exposed key now.

### 3. Data Exposure — SELECT *: `server.ts:35-36`
- **Severity:** MEDIUM
- **Confidence:** 8/10
- **Description:** `SELECT *` may expose password hashes, tokens, PII columns to caller.
- **Fix:** Enumerate only needed columns in the SELECT clause.

### 4. Unvalidated Payment Input: `server.ts:22-32`
- **Severity:** MEDIUM
- **Confidence:** 9/10
- **Description:** `amount` and `token` passed to Stripe without validation. Negative/zero amounts, non-token strings accepted.
- **Fix:** Validate with Zod before forwarding to Stripe.

### 5. Stripe Response Proxied Verbatim: `server.ts:31`
- **Severity:** MEDIUM
- **Confidence:** 8/10
- **Description:** Raw Stripe API response including internal metadata forwarded to client.
- **Fix:** Extract only required fields before responding.

**Positive practices (security pass):** Parameterized query on `/users/:id`; `DATABASE_URL` from environment.

---

## Appendix B — Raw Architecture Review Pass (Agent 2 inline output)

### 1. Unhandled async errors — all routes: `server.ts:13, 21, 34`
- **Severity:** HIGH
- **Issue:** Async handlers with no try/catch and no `next(err)` call. Express 4 will hang requests on rejection; Node 15+ will crash process.
- **Suggestion:** Use `express-async-errors` package or wrap with try/catch + `next(err)`.

### 2. No Zod/schema validation at any boundary: `server.ts:14, 22-23`
- **Severity:** MEDIUM
- **Issue:** `req.query`, `req.body`, `req.params` accepted without validation.
- **Suggestion:** Add Zod schemas at each route boundary.

### 3. No graceful shutdown: `server.ts:40`
- **Severity:** MEDIUM
- **Issue:** No SIGTERM/SIGINT handling; pg pool not drained on shutdown.
- **Suggestion:** Register process signal handlers to close server and pool.

### 4. No env config validation at startup: `server.ts:5-7`
- **Severity:** MEDIUM
- **Issue:** `DATABASE_URL` consumed without existence/format check; fails late and obscurely.
- **Suggestion:** Parse all env vars with Zod at startup, fail fast.

### 5. Side effect on import — Pool constructor at module top-level: `server.ts:5-7`
- **Severity:** LOW
- **Issue:** DB connection opened at module load time, preventing testability without live DB.
- **Suggestion:** Wrap in a `start()` function.

**Positive practices (architecture pass):** Consistent async/await style; `express.json()` properly positioned before routes; correct parameterized query pattern used in one route showing the developer knows the right approach.

---

## Appendix C — Raw Stack-Specific Review Pass (Agent 3 inline output)

### 1. `req.query.name` not narrowed to `string`: `server.ts:14`
- **Severity:** MEDIUM
- **Issue:** Express `req.query` member has union type including arrays and objects. Using directly in template literal is a TS type error and a runtime hazard.
- **Suggestion:** `if (typeof name !== 'string') return res.status(400)...`

### 2. `parseInt` not guarded against `NaN`: `server.ts:35`
- **Severity:** LOW
- **Issue:** `parseInt('abc', 10)` → `NaN`; pg query fails unhandled.
- **Suggestion:** Add `Number.isInteger(id)` guard.

### 3. No CORS middleware: `server.ts:10-11`
- **Severity:** MEDIUM
- **Issue:** No CORS policy defined. Browser-side clients will either be blocked silently or receive wildcard access depending on defaults.
- **Suggestion:** Add `cors()` middleware with explicit origin allowlist.

### 4. Hardcoded port `3000`: `server.ts:40`
- **Severity:** LOW
- **Issue:** Port not configurable via environment; fails in containerized deployments.
- **Suggestion:** `const PORT = Number(process.env.PORT) || 3000;`

**Positive practices (stack-specific pass):** Native `fetch` used for Stripe HTTP call (no unnecessary axios dep); pg parameterized query (`$1`) on the `/users/:id` route shows correct pg driver usage.
