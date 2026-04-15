# Code Review: server.ts

**File reviewed:** `/home/maradrash/Projects/AI/ai-workflow/code-review-workspace/iteration-1/fixtures/ts-api/server.ts`
**Reviewer:** Claude (automated)
**Date:** 2026-04-15

---

## Summary

41-line Express + pg API server. Contains two critical security defects and several code-quality gaps. The file should not be shipped in its current form.

---

## Findings

### FINDING-1 — Hardcoded Live Stripe Secret Key
**Severity: HIGH**
**File:line:** `server.ts:4`

```ts
const STRIPE_API_KEY = "sk_live_EXAMPLE_PLANTED_FIXTURE_NOT_A_REAL_KEY";
```

A live Stripe secret key is committed directly in source code. Anyone with read access to the repository — including CI workers, contractors, or future contributors — can use this key to create charges, issue refunds, read customer data, and enumerate payment methods against the live Stripe account. Once a key appears in git history it must be considered permanently compromised even after removal.

**Recommended fix:**
1. Immediately rotate the key in the Stripe dashboard.
2. Load the key exclusively from an environment variable:
   ```ts
   const STRIPE_API_KEY = process.env.STRIPE_API_KEY;
   if (!STRIPE_API_KEY) throw new Error("STRIPE_API_KEY env var is required");
   ```
3. Add `sk_live_` and `sk_test_` patterns to a `.gitignore`-style pre-commit secret-scanning hook (e.g. `gitleaks`, `trufflehog`).

---

### FINDING-2 — SQL Injection via String Interpolation
**Severity: HIGH**
**File:line:** `server.ts:15-17`

```ts
const result = await pool.query(
  `SELECT id, email, name FROM users WHERE name LIKE '%${name}%'`,
);
```

`name` is taken directly from `req.query` without any sanitization or parameterization. An attacker can supply a value such as `' OR '1'='1` or `'; DROP TABLE users; --` to read arbitrary rows or (depending on the Postgres user's privileges) destroy data. The `LIKE` wildcard also means an empty `name` returns all users.

**Recommended fix:**
Use a parameterized query. The `pg` driver supports `$N` placeholders inside `LIKE` patterns:
```ts
const { name } = req.query;
const safeName = typeof name === "string" ? name : "";
const result = await pool.query(
  "SELECT id, email, name FROM users WHERE name ILIKE $1",
  [`%${safeName}%`],
);
```
The `%` wildcards belong in the value, not the SQL template. This is safe because the driver serializes the value independently of the query string.

---

### FINDING-3 — No Input Validation on Query or Body Parameters
**Severity: MEDIUM**
**File:line:** `server.ts:14`, `server.ts:22`

Neither `/users/search` nor `/charge` validates that required fields are present or of the expected type before use. Concretely:

- `name` could be `undefined`, an array (`string[]`), or an object (Express parses repeated query params as arrays). Interpolating an array into a SQL string produces `[object Array]`.
- `amount` is passed directly to `String(amount)` and then to Stripe; a negative amount, a non-numeric string, or a zero value may pass Stripe validation but produce a refund or zero-value charge.
- `token` could be `undefined`, causing a malformed Stripe request with no useful error surfaced to the caller.

**Recommended fix:**
Add schema validation at the route entry point (e.g. with `zod`):
```ts
import { z } from "zod";

const SearchQuery = z.object({ name: z.string().min(1).max(100) });
const ChargeBody = z.object({
  amount: z.number().int().positive(),
  token: z.string().min(1),
});
```
Return a structured 400 response on validation failure before touching the database or Stripe.

---

### FINDING-4 — Unhandled Promise Rejections / No Error Handling
**Severity: MEDIUM**
**File:line:** `server.ts:13-18`, `server.ts:21-32`, `server.ts:34-38`

All three route handlers are `async` functions but none have `try/catch` blocks. A database connectivity error, a Stripe network timeout, or any thrown exception will result in an unhandled promise rejection. In Express 4 this crashes the process (or silently hangs the request in older versions). In Express 5 the error is forwarded to the default error handler, but the default handler exposes a stack trace to the client in development mode and returns an empty 500 in production — neither is acceptable.

**Recommended fix:**
Wrap each handler body or use a wrapper utility:
```ts
app.get("/users/search", async (req, res, next) => {
  try {
    // ...
  } catch (err) {
    next(err);
  }
});
```
Or install `express-async-errors` to automatically forward async rejections to the Express error pipeline, and add a global error handler that logs the error and returns a safe JSON response without leaking internals.

---

### FINDING-5 — Sensitive Data Over-Exposure in `/users/:id`
**Severity: MEDIUM**
**File:line:** `server.ts:36`

```ts
const result = await pool.query("SELECT * FROM users WHERE id = $1", [id]);
res.json(result.rows[0]);
```

`SELECT *` returns every column in `users`, which likely includes password hashes, internal flags, or other fields that should never leave the server. Returning `undefined` when no row is found also produces a 200 with `null` body rather than a 404, leaking the difference between a user that does not exist and one that has no data.

**Recommended fix:**
Enumerate only the columns the client needs:
```ts
const result = await pool.query(
  "SELECT id, name, email, created_at FROM users WHERE id = $1",
  [id],
);
if (!result.rows[0]) return res.status(404).json({ error: "Not found" });
res.json(result.rows[0]);
```

---

### FINDING-6 — Stripe API Response Forwarded Raw to Client
**Severity: MEDIUM**
**File:line:** `server.ts:31`

```ts
res.json(await response.json());
```

The raw Stripe API response — which may include internal charge IDs, risk evaluation fields, payment method fingerprints, and other sensitive metadata — is sent directly to the caller. The Stripe HTTP status is also discarded; a failed charge (402, 400) is silently forwarded with a 200 status, so clients cannot distinguish success from failure.

**Recommended fix:**
Parse the Stripe response, check for errors, map to a safe outbound shape, and mirror the appropriate HTTP status:
```ts
const stripeData = await response.json() as { error?: { message: string }; id?: string };
if (!response.ok || stripeData.error) {
  return res.status(402).json({ error: stripeData.error?.message ?? "Charge failed" });
}
res.status(201).json({ chargeId: stripeData.id });
```

---

### FINDING-7 — `parseInt` Without NaN Guard on Route Parameter
**Severity: LOW**
**File:line:** `server.ts:35`

```ts
const id = parseInt(req.params.id, 10);
```

If `req.params.id` is not a valid integer, `parseInt` returns `NaN`. Passing `NaN` as a parameterized value to `pg` causes a query error (unhandled; see FINDING-4) rather than a clean 400 response.

**Recommended fix:**
```ts
const id = parseInt(req.params.id, 10);
if (Number.isNaN(id)) return res.status(400).json({ error: "Invalid id" });
```

---

### FINDING-8 — No Authentication or Authorization on Any Route
**Severity: HIGH** (architectural gap)
**File:line:** `server.ts:13`, `server.ts:21`, `server.ts:34`

None of the three routes require authentication. Any unauthenticated caller can:
- Enumerate all users by name fragment (FINDING-1 compounds this — trivially extract full tables).
- Trigger a Stripe charge with an arbitrary amount and token.
- Retrieve any user record by ID.

**Recommended fix:**
Add middleware that validates a bearer token (JWT or session) before any route handler. At minimum, the `/charge` endpoint must require the authenticated user's identity to be resolved from the token — never trust a client-supplied `token` alone without binding it to a verified session.

---

### FINDING-9 — Server Binds to All Interfaces on a Fixed Port, No Configuration
**Severity: LOW**
**File:line:** `server.ts:40`

```ts
app.listen(3000);
```

The port is hardcoded and there is no callback to confirm successful binding. In containerized or cloud environments, the port should be configurable via `process.env.PORT` and the listen callback should log the bound address (or throw on error).

**Recommended fix:**
```ts
const PORT = Number(process.env.PORT) || 3000;
app.listen(PORT, () => console.log(`Server listening on port ${PORT}`));
```

---

## Severity Summary

| Severity | Count | Finding IDs |
|----------|-------|-------------|
| HIGH     | 3     | FINDING-1, FINDING-2, FINDING-8 |
| MEDIUM   | 4     | FINDING-3, FINDING-4, FINDING-5, FINDING-6 |
| LOW      | 2     | FINDING-7, FINDING-9 |
| **Total**| **9** | |

---

## Priority Action Order

1. **Rotate the Stripe key immediately** (FINDING-1) — this is a live credential breach.
2. **Fix the SQL injection** (FINDING-2) — trivially exploitable with no authentication barrier.
3. **Add authentication middleware** (FINDING-8) — no route should be publicly callable.
4. **Add input validation** (FINDING-3) and **error handling** (FINDING-4) together before the next deployment.
5. Address FINDING-5, FINDING-6, FINDING-7, FINDING-9 in the same sprint.
