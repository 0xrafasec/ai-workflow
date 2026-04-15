# Code Review: auth.py

**File reviewed:** `/home/maradrash/Projects/AI/ai-workflow/code-review-workspace/iteration-1/fixtures/py-auth/auth.py`
**Date:** 2026-04-15
**Reviewer:** Claude (automated code review)

---

## Summary

This Flask application implements login, password reset, and user deletion endpoints. It contains multiple critical and high-severity security vulnerabilities — including a hardcoded backdoor reset token, no authentication on an admin-delete endpoint, use of a broken hash algorithm, and a timing side-channel in password comparison — as well as several architecture and code-quality problems. No production use of this file should be considered until all HIGH findings are resolved.

---

## Findings

### FINDING 1 — Hardcoded Backdoor Reset Token

**Severity:** HIGH
**File:Line:** `auth.py:38`

```python
if token == "master-reset-2024":
```

The password-reset endpoint accepts a literal, hardcoded secret token baked into source code. Any developer, auditor, or attacker with access to the repository can reset any user's password to anything. The token never rotates and cannot be revoked without a code deployment. This is a textbook hardcoded-credential vulnerability (CWE-798).

**Recommended fix:**
- Remove the hardcoded token entirely.
- Issue per-user, time-limited reset tokens (e.g. signed JWTs or a cryptographic random token stored in a short-TTL store) that are tied to the requesting user's identity and invalidated after first use.
- Require the user to authenticate (e.g. via email link) before the reset is honoured.

---

### FINDING 2 — Admin Delete-User Endpoint Has No Authentication or Authorisation

**Severity:** HIGH
**File:Line:** `auth.py:45-51`

```python
@app.route("/admin/delete-user", methods=["POST"])
def delete_user():
    username = request.get_json().get("username", "")
    if username in USERS:
        del USERS[username]
```

Any anonymous HTTP client can delete any user simply by knowing (or guessing) a username. There is no token check, session check, or role check of any kind. The `/admin/` prefix in the route name gives a false impression of protection.

**Recommended fix:**
- Require a valid, authenticated admin session/token for this endpoint — at minimum check a session cookie or Bearer token and verify the caller has an admin role.
- Apply the same requirement to all routes under `/admin/`.
- Consider rate limiting and audit logging for destructive operations.

---

### FINDING 3 — MD5 Used for Password Hashing

**Severity:** HIGH
**File:Line:** `auth.py:14`, `auth.py:8-10`

```python
def hash_password(pw: str) -> str:
    return hashlib.md5(pw.encode()).hexdigest()
```

MD5 is a general-purpose cryptographic hash, not a password hash. It is:
- Broken as a collision-resistant hash (CWE-327).
- Extremely fast, making brute-force and rainbow-table attacks trivial (a modern GPU can test billions of MD5 hashes per second).
- Already cracked for the two stored hashes: `5f4dcc3b5aa765d61d8327deb882cf99` = "password", `e10adc3949ba59abbe56e057f20f883e` = "123456". These are among the most common passwords on the internet, confirming the stored values are in every public rainbow table.

**Recommended fix:**
- Replace `hashlib.md5` with `bcrypt`, `argon2-cffi`, or `hashlib.scrypt` / `hashlib.pbkdf2_hmac` with a high iteration count.
- Use a unique, random per-user salt (bcrypt and argon2 handle this automatically).
- Force a password reset for all existing users to retire the MD5 hashes.

---

### FINDING 4 — Timing Side-Channel in Password Comparison

**Severity:** HIGH
**File:Line:** `auth.py:27`

```python
if hash_password(password) == stored:
```

Python's `==` operator on strings short-circuits on the first differing byte, leaking information about how many leading bytes of the hash match. An attacker who can make many repeated login requests and measure response times can use this oracle to reconstruct hash characters one byte at a time (CWE-208). When combined with the MD5 weakness above, the attack surface is significantly larger.

**Recommended fix:**
- Use `hmac.compare_digest(hash_password(password), stored)` for all hash comparisons. This performs a constant-time comparison regardless of the position of the first mismatch.
- Note: switching to a proper password KDF (bcrypt/argon2) and using that library's own `verify` function is the correct long-term fix; those functions include built-in constant-time comparison.

---

### FINDING 5 — Credentials Stored in Plaintext In-Memory Dictionary

**Severity:** HIGH
**File:Line:** `auth.py:7-10`

```python
USERS = {
    "admin": "5f4dcc3b5aa765d61d8327deb882cf99",
    "alice": "e10adc3949ba59abbe56e057f20f883e",
}
```

All user credentials live in a module-level global dictionary. Any password change (via `/reset`) is lost the moment the process restarts. Beyond the loss-on-restart problem, having credentials as a module global means any code in the same process can read or mutate them directly, with no access control boundary.

**Recommended fix:**
- Store user credentials in a persistent, properly access-controlled data store (e.g. a database with hashed passwords and parameterised queries).
- Never commit credential hashes to version control, even hashed ones.

---

### FINDING 6 — Insecure Token Format Returned on Successful Login

**Severity:** HIGH
**File:Line:** `auth.py:28`

```python
return jsonify({"token": username + ":ok"}), 200
```

The "token" returned is simply `"<username>:ok"` — a trivially forgeable string with no cryptographic value. Any client can craft `"admin:ok"` without ever authenticating. If any downstream code trusts this token to make authorisation decisions, it represents a complete authentication bypass.

**Recommended fix:**
- Issue a signed token (e.g. a JWT signed with a server-side secret using HS256 or RS256, with `exp`, `iat`, and `sub` claims) or a securely random opaque session token stored server-side.
- Never embed the username in the token without a cryptographic signature.

---

### FINDING 7 — Flask debug=True Exposed on 0.0.0.0

**Severity:** HIGH
**File:Line:** `auth.py:55`

```python
app.run(debug=True, host="0.0.0.0")
```

Running Flask with `debug=True` enables the Werkzeug interactive debugger, which executes arbitrary Python code in the browser when an unhandled exception occurs — no authentication required. Binding to `0.0.0.0` means this debugger is reachable from any network interface, not just localhost. This is a remote code execution vulnerability in any non-localhost environment (CWE-94).

**Recommended fix:**
- Never use `debug=True` outside of local development. Control it via an environment variable: `debug=os.environ.get("FLASK_DEBUG", "false").lower() == "true"`.
- Use a production WSGI server (gunicorn, uWSGI) instead of Flask's built-in development server for any non-local deployment.
- At minimum, bind to `127.0.0.1` in development: `host="127.0.0.1"`.

---

### FINDING 8 — Unauthenticated Password Reset Allows Arbitrary User Enumeration and Account Takeover

**Severity:** HIGH
**File:Line:** `auth.py:38-41`

```python
if token == "master-reset-2024":
    username = data.get("username", "")
    USERS[username] = hash_password(new_password)
```

In addition to the hardcoded token (Finding 1), the reset endpoint accepts an arbitrary `username` from the request body and writes to `USERS[username]` without checking whether `username` is a valid existing user. An attacker with the hardcoded token can inject new usernames into the user store. The lack of input validation makes this an unauthenticated privilege escalation vector (CWE-306).

**Recommended fix:**
- Validate that `username` exists in the user store before allowing a reset.
- Redesign the endpoint so it operates on the currently-authenticated user only, not an attacker-supplied username.

---

### FINDING 9 — No Input Validation on Request Body

**Severity:** MEDIUM
**File:Line:** `auth.py:19-21`, `auth.py:35-36`, `auth.py:47`

```python
data = request.get_json()
username = data.get("username", "")
password = data.get("password", "")
```

`request.get_json()` returns `None` if the `Content-Type` header is not `application/json` or the body is malformed JSON, which causes an unhandled `AttributeError` on the `.get()` call. This crashes the request with a 500 response and could expose stack traces to the caller. There is also no length or character validation on any field.

**Recommended fix:**
- Check that `data` is not `None` before accessing fields; return a 400 response if the body is absent or malformed.
- Use a validation library (e.g. marshmallow, pydantic, or Flask-Pydantic) to declare required fields, their types, and maximum lengths.
- Enforce a maximum length on `username` and `password` to prevent denial-of-service via oversized inputs (CWE-400).

---

### FINDING 10 — Verbose, Uniform Error Message Leaks Minimal Information (Good), But Timing Differs By Code Path

**Severity:** MEDIUM
**File:Line:** `auth.py:24-29`

```python
stored = USERS.get(username)
if stored is None:
    return jsonify({"error": "invalid"}), 401   # fast path — no hashing

if hash_password(password) == stored:
    ...
return jsonify({"error": "invalid"}), 401       # slow path — hashing done
```

The error message is intentionally generic ("invalid"), which is good practice. However, the code has two separate early-exit paths: one that skips hashing (fast) and one that hashes then fails (slow). The measurable time difference allows an attacker to enumerate valid usernames (CWE-204).

**Recommended fix:**
- Always hash the provided password, even for unknown usernames. A common pattern is to hash against a dummy stored hash so the work is consistent:
  ```python
  DUMMY_HASH = hash_password("dummy-constant-value")
  stored = USERS.get(username, DUMMY_HASH)
  if not hmac.compare_digest(hash_password(password), stored):
      return jsonify({"error": "invalid"}), 401
  ```
  With a proper KDF (bcrypt/argon2), use the library's built-in dummy-verify support.

---

### FINDING 11 — No Rate Limiting on Authentication Endpoints

**Severity:** MEDIUM
**File:Line:** `auth.py:17-29` (login route), `auth.py:32-42` (reset route)

There is no rate limiting, account lockout, or brute-force protection on any endpoint. An attacker can submit unlimited login or reset attempts, enabling dictionary and brute-force attacks.

**Recommended fix:**
- Apply rate limiting at the application level (e.g. `flask-limiter`) or at a reverse-proxy/gateway level (nginx, API gateway).
- Implement exponential backoff or temporary lockout after a configurable number of consecutive failures per username or IP.
- Log and alert on anomalous authentication patterns.

---

### FINDING 12 — Mutable Global State Is Not Thread-Safe

**Severity:** MEDIUM
**File:Line:** `auth.py:7`, `auth.py:40`, `auth.py:49`

```python
USERS = { ... }          # shared mutable dict
USERS[username] = ...    # write in /reset
del USERS[username]      # write in /delete-user
```

Flask under a multi-threaded or multi-process WSGI server (which is the recommended production deployment) will have concurrent access to `USERS` without any locking. Concurrent writes can cause data corruption or partial state (CWE-362).

**Recommended fix:**
- Move to a proper persistent data store (see Finding 5). The underlying database will handle concurrent access via transactions.
- If in-memory state must be used for testing, protect mutations with a `threading.Lock`.

---

### FINDING 13 — No Logging or Audit Trail

**Severity:** MEDIUM
**File:Line:** `auth.py:17-51` (all routes)

Authentication failures, successful logins, password resets, and user deletions are entirely silent — no log lines are emitted. This makes forensic investigation after a breach impossible and violates common compliance requirements (PCI-DSS, SOC 2).

**Recommended fix:**
- Log authentication attempts (success and failure) including timestamp, username (not password), source IP, and outcome.
- Log password resets and user deletions with actor identity.
- Use Python's `logging` module with structured output; do not print credentials or password hashes.

---

### FINDING 14 — No HTTPS Enforcement

**Severity:** MEDIUM
**File:Line:** `auth.py:54-55`

```python
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
```

The application is served over plain HTTP. Credentials, tokens, and reset codes transmitted to this server are exposed to network eavesdropping (CWE-319).

**Recommended fix:**
- Terminate TLS at a reverse proxy (nginx, Caddy) or load balancer; never at the Flask dev server.
- Set Flask's `SESSION_COOKIE_SECURE = True` and `SESSION_COOKIE_HTTPONLY = True` once HTTPS is in place.
- Enforce HTTPS at the application layer with an HSTS header.

---

### FINDING 15 — Credentials Hardcoded Directly in Source Code

**Severity:** MEDIUM
**File:Line:** `auth.py:7-10`

```python
USERS = {
    "admin": "5f4dcc3b5aa765d61d8327deb882cf99",
    "alice": "e10adc3949ba59abbe56e057f20f883e",
}
```

Seeding a user store with hardcoded values — even hashed — couples deployment configuration to source code and makes credential rotation impossible without a code change. These hashes are also trivially reversible (see Finding 3).

**Recommended fix:**
- Remove all hardcoded credentials. Provision users via an initialisation script or database migration that reads secrets from environment variables or a secrets manager.
- Rotate all credentials immediately, as the underlying values ("password", "123456") are publicly known.

---

### FINDING 16 — No CSRF Protection

**Severity:** MEDIUM
**File:Line:** `auth.py:17-51` (all POST routes)

State-changing POST endpoints do not validate a CSRF token. A malicious page can trick a logged-in user's browser into issuing a cross-origin POST (though Flask does not set `SameSite` on session cookies by default, which partially mitigates browser-based CSRF for JSON-only endpoints, the lack of any explicit protection is still a gap).

**Recommended fix:**
- For browser-facing endpoints, use Flask-WTF's CSRF protection or enforce `SameSite=Strict` on all session cookies.
- Validate `Content-Type: application/json` strictly; reject requests without it to reduce the CSRF surface.

---

### FINDING 17 — `os` Module Imported But Never Used

**Severity:** LOW
**File:Line:** `auth.py:2`

```python
import os
```

The `os` module is imported but never referenced anywhere in the file. Unused imports add noise, can mislead readers into thinking environment variables are being used for configuration, and may be flagged by linters.

**Recommended fix:**
- Remove the unused `import os` line. (When `debug` is controlled via environment variable as recommended in Finding 7, this import will become necessary and can be re-added at that time.)

---

### FINDING 18 — No Type Annotations on Route Functions

**Severity:** LOW
**File:Line:** `auth.py:18`, `auth.py:33`, `auth.py:46`

Route handler functions lack return type annotations, reducing IDE support and making it harder for type checkers to catch errors.

**Recommended fix:**
- Annotate return types: `def login() -> tuple[flask.Response, int]:` (or use `flask.typing.ResponseReturnValue`).
- Run `mypy` or `pyright` as part of CI.

---

### FINDING 19 — No Structured Error Handling / HTTP 500 on Unexpected Input

**Severity:** LOW
**File:Line:** `auth.py:19`, `auth.py:35`, `auth.py:47`

If `request.get_json()` returns `None` (malformed body, wrong Content-Type), the subsequent `.get()` call raises `AttributeError`, resulting in an unhandled exception. Flask returns a 500 with a full stack trace in debug mode (see Finding 7).

**Recommended fix:**
- Wrap request parsing in a try/except, or use `request.get_json(silent=True)` combined with an explicit `None` check and a 400 response.

---

## Findings Summary

| Severity | Count |
|----------|-------|
| HIGH     | 8     |
| MEDIUM   | 7     |
| LOW      | 4     |
| **Total**| **19**|

---

## Priority Remediation Order

1. **Immediately:** Remove the hardcoded `master-reset-2024` token (Finding 1) and add authentication to `/admin/delete-user` (Finding 2).
2. **Before any network exposure:** Disable `debug=True` and stop binding to `0.0.0.0` (Finding 7).
3. **Before storing any real user data:** Replace MD5 with bcrypt/argon2 (Finding 3); use constant-time comparison (Finding 4); replace the forgeable token with a signed JWT (Finding 6).
4. **Short-term hardening:** Add input validation (Finding 9), username-enumeration timing fix (Finding 10), rate limiting (Finding 11), and audit logging (Finding 13).
5. **Architecture:** Move `USERS` out of in-memory global state into a persistent store (Findings 5, 12, 15).
6. **Polish:** Fix unused import, add type annotations, enforce HTTPS, add CSRF protection (Findings 14, 16, 17, 18).
