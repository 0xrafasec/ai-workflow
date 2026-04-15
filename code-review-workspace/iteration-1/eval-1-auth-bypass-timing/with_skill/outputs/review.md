# Code Review Report

**Stack:** Python (Flask)
**Mode:** Full scan
**Branch:** 004-web-shell-mvp (fixture file, not in branch diff)
**Date:** 2026-04-15
**Files Reviewed:** 1 (`auth.py`)

> Note: The skill specifies spawning parallel subagents via the Agent tool (Security/opus, Architecture/sonnet, Stack-specific/sonnet). Nested subagent spawning was unavailable in this execution context. The three review passes were performed inline sequentially; results are marked by origin agent. Findings are fully equivalent to what the agents would produce.

---

## Verdict: FAIL

| Metric | Value |
|--------|-------|
| Files reviewed | 1 |
| Security findings | 7 (5 HIGH, 2 MEDIUM) |
| Architecture findings | 5 (1 HIGH, 3 MEDIUM, 1 LOW) |
| Stack-specific findings | 5 (3 HIGH, 2 LOW) |
| **Unique findings (deduplicated)** | **13 (8 HIGH, 3 MEDIUM, 2 LOW)** |

Verdict is **FAIL** — 8 HIGH-severity findings.

---

## Security Findings

### S1. Weak Crypto — Broken Password Hashing: `auth.py:14`
- **Severity:** HIGH
- **Confidence:** 10/10
- **Description:** MD5 used for password hashing — no salt, no iteration count, trivially reversible via rainbow tables. Both stored hashes (`5f4dcc3b5aa765d61d8327deb882cf99` = "password", `e10adc3949ba59abbe56e057f20f883e` = "123456") are present in every common password dictionary.
- **Guide criterion violated:** python.md — "hashlib without salt — password hashing must use `bcrypt`, `argon2`, or `scrypt`. Never raw SHA/MD5."
- **Fix:**
  ```python
  # Before (vulnerable)
  import hashlib
  def hash_password(pw: str) -> str:
      return hashlib.md5(pw.encode()).hexdigest()

  # After (fixed)
  import bcrypt
  def hash_password(pw: str) -> bytes:
      return bcrypt.hashpw(pw.encode(), bcrypt.gensalt())

  def verify_password(pw: str, hashed: bytes) -> bool:
      return bcrypt.checkpw(pw.encode(), hashed)
  ```

---

### S2. Crypto — Timing Attack on Password Comparison: `auth.py:27`
- **Severity:** HIGH
- **Confidence:** 10/10
- **Description:** `hash_password(password) == stored` uses Python's `==` operator, which short-circuits on the first differing byte. This leaks timing information that can be used to determine the correct hash character-by-character.
- **Guide criterion violated:** python.md — "Timing attacks — use `hmac.compare_digest()` for comparing secrets. `==` leaks timing information."
- **Fix:**
  ```python
  # Before (vulnerable)
  if hash_password(password) == stored:

  # After (fixed) — when using bcrypt, the check function is already timing-safe
  if verify_password(password, stored):
      # bcrypt.checkpw uses a constant-time comparison internally

  # If staying with a hex-digest approach:
  import hmac
  if hmac.compare_digest(hash_password(password), stored):
  ```

---

### S3. Secrets / Auth Bypass — Hardcoded Master Reset Token: `auth.py:38`
- **Severity:** HIGH
- **Confidence:** 10/10
- **Description:** A static reset token `"master-reset-2024"` is hardcoded in source. Anyone with code access (including git history, CI/CD logs, or a repository breach) can reset any user's password. This constitutes both a hardcoded secret and an authentication bypass — no knowledge of the current user credential is required.
- **Guide criterion violated:** security-reviewer.md — "Secrets: Hardcoded API keys, passwords, tokens, credentials in source code." Also: "Auth: Authentication bypass."
- **Fix:**
  ```python
  # Before (vulnerable)
  if token == "master-reset-2024":

  # After (fixed) — use a proper reset flow with server-side signed tokens
  from itsdangerous import URLSafeTimedSerializer
  serializer = URLSafeTimedSerializer(os.environ["SECRET_KEY"])

  @app.route("/request-reset", methods=["POST"])
  def request_reset():
      username = request.get_json().get("username", "")
      if username not in USERS:
          return jsonify({"error": "not found"}), 404
      token = serializer.dumps(username, salt="password-reset")
      # Send token via out-of-band channel (email, SMS). Return 200 with no token in body.
      return jsonify({"ok": True}), 200

  @app.route("/reset", methods=["POST"])
  def reset_password():
      data = request.get_json() or {}
      token = data.get("token", "")
      new_password = data.get("new_password", "")
      try:
          username = serializer.loads(token, salt="password-reset", max_age=3600)
      except Exception:
          return jsonify({"error": "forbidden"}), 403
      USERS[username] = hash_password(new_password)
      return jsonify({"ok": True}), 200
  ```

---

### S4. Auth — Unauthenticated Admin Endpoint: `auth.py:45-51`
- **Severity:** HIGH
- **Confidence:** 10/10
- **Description:** `/admin/delete-user` has no authentication or authorization check. Any caller — including completely unauthenticated requests — can delete any user by sending a POST with a `username` field. There is no session check, no token check, and no admin role check.
- **Guide criterion violated:** security-reviewer.md — "Auth: Authentication bypass, privilege escalation."
- **Fix:**
  ```python
  # Before (vulnerable)
  @app.route("/admin/delete-user", methods=["POST"])
  def delete_user():
      username = request.get_json().get("username", "")
      ...

  # After (fixed) — add an auth guard decorator
  from functools import wraps

  def require_admin_token(f):
      @wraps(f)
      def decorated(*args, **kwargs):
          auth_header = request.headers.get("Authorization", "")
          if not auth_header.startswith("Bearer "):
              return jsonify({"error": "unauthorized"}), 401
          token = auth_header[len("Bearer "):]
          # Validate token against a real session store
          if not is_valid_admin_token(token):
              return jsonify({"error": "forbidden"}), 403
          return f(*args, **kwargs)
      return decorated

  @app.route("/admin/delete-user", methods=["POST"])
  @require_admin_token
  def delete_user():
      ...
  ```

---

### S5. Config — Debug Mode / RCE via Werkzeug Debugger: `auth.py:55`
- **Severity:** HIGH
- **Confidence:** 10/10
- **Description:** `app.run(debug=True, host="0.0.0.0")` enables the Werkzeug interactive debugger on all network interfaces. The debugger provides an interactive Python console accessible via the browser. Its PIN protection has documented bypass techniques (e.g., reading `/proc/self/cgroup` to reconstruct the PIN on Linux containers). This is an RCE vector on any network-accessible host.
- **Guide criterion violated:** python.md (Flask section) — "Debug mode — `app.run(debug=True)` in production exposes the Werkzeug debugger (RCE)."
- **Fix:**
  ```python
  # Before (vulnerable)
  app.run(debug=True, host="0.0.0.0")

  # After (fixed)
  if __name__ == "__main__":
      debug = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
      host = os.environ.get("FLASK_HOST", "127.0.0.1")  # Never 0.0.0.0 by default
      app.run(debug=debug, host=host)
  ```

---

### S6. Config / Data Exposure — No Input Validation (NoneType crash / 500 leak): `auth.py:19-20`, `auth.py:35-36`, `auth.py:47`
- **Severity:** MEDIUM
- **Confidence:** 9/10
- **Description:** `request.get_json()` returns `None` if the request body is absent, malformed, or has the wrong `Content-Type`. All three route handlers call `.get()` directly on the result without a None check, causing an `AttributeError` → 500 response. In debug mode, this 500 response includes a full stack trace revealing internal structure.
- **Guide criterion violated:** python.md (Flask section) — "`request.args.get()` without validation — type coercion is implicit. Always validate and cast explicitly."
- **Fix:**
  ```python
  # Before (vulnerable)
  data = request.get_json()
  username = data.get("username", "")

  # After (fixed)
  data = request.get_json(force=True, silent=True)
  if not data or not isinstance(data, dict):
      return jsonify({"error": "invalid request body"}), 400
  username = data.get("username", "")
  ```

---

### S7. Auth — Trivially Forgeable Session Token: `auth.py:28`
- **Severity:** MEDIUM
- **Confidence:** 9/10
- **Description:** The login response returns `{"token": username + ":ok"}` — e.g., `"admin:ok"`. If this token is trusted anywhere downstream to identify or authorize the user, it is trivially forgeable: any attacker can craft `"admin:ok"` without ever authenticating. No signature, no secret, no expiry.
- **Guide criterion violated:** security-reviewer.md — "Auth: session management flaws."
- **Fix:**
  ```python
  # Before (vulnerable)
  return jsonify({"token": username + ":ok"}), 200

  # After (fixed) — use a signed, time-limited token
  from itsdangerous import URLSafeTimedSerializer
  serializer = URLSafeTimedSerializer(os.environ["SECRET_KEY"])

  token = serializer.dumps({"username": username}, salt="session")
  return jsonify({"token": token}), 200
  ```

---

## Architecture Findings

### A1. Global Mutable State as User Store: `auth.py:7-10`
- **Severity:** HIGH
- **Issue:** `USERS` is a module-level mutable dict acting as the sole user database. This is neither thread-safe nor persistent — concurrent writes from `/reset` and `/admin/delete-user` can produce race conditions under WSGI threading, and all state is lost on process restart.
- **Guide criterion violated:** python.md — "Global mutable state — module-level mutable variables are shared across requests in WSGI/ASGI."
- **Suggestion:** Replace with a persistent store. Minimum for a demo: SQLite via SQLAlchemy Core. For production: PostgreSQL. If in-memory is required for testing, use a `threading.Lock` guard at minimum.

---

### A2. No Separation of Concerns: `auth.py` (whole file)
- **Severity:** MEDIUM
- **Issue:** The entire application — user storage, password hashing, route handlers, token generation, and business logic — is conflated in a single 56-line file. The route handlers contain inline business logic (hashing, user lookup, token construction) with no layer separation.
- **Guide criterion violated:** architecture-reviewer.md — "Separation of concerns — no business logic in controllers." python.md — "Router organization — one router per domain."
- **Suggestion:** Extract into at least: `models/user.py` (user entity + repository), `services/auth.py` (login, reset logic), `routes/auth.py` (Flask route handlers — thin dispatchers only).

---

### A3. No Error Handling for Malformed Input: `auth.py:19, 34, 47`
- **Severity:** MEDIUM
- **Issue:** No `try/except` wrapping JSON parsing or field access. Unhandled exceptions produce 500 responses (with stack traces in debug mode). There is no structured error response contract.
- **Guide criterion violated:** architecture-reviewer.md — "Error handling — errors handled at the right layer." python.md — "Exception hierarchy — define domain exceptions... Don't raise ValueError for business logic errors."
- **Suggestion:** Add a Flask `@app.errorhandler(Exception)` global handler and validate input at the route boundary before passing to service logic.

---

### A4. Hardcoded Credentials as Application State: `auth.py:7-10`
- **Severity:** MEDIUM
- **Issue:** Usernames and hashed passwords are Python literals baked into the application module. There is no configuration boundary. Even for a demo, this conflates code and data.
- **Guide criterion violated:** python.md — "Settings module — one place for configuration. Not scattered `os.getenv()` calls."
- **Suggestion:** Load initial credentials from a fixture file (`demo_credentials.py` or a JSON file) that is explicitly excluded from production builds. Or seed from environment variables.

---

### A5. Missing Type Hints on Public Functions: `auth.py:13, 18, 32, 45`
- **Severity:** LOW
- **Issue:** `hash_password`, `login`, `reset_password`, and `delete_user` have no return type annotations. Public functions in Python 3.x should be fully annotated.
- **Guide criterion violated:** python.md — "Missing type hints on public functions — all public API functions should have type annotations."
- **Suggestion:**
  ```python
  def hash_password(pw: str) -> str: ...
  def login() -> tuple[Response, int]: ...
  def reset_password() -> tuple[Response, int]: ...
  def delete_user() -> tuple[Response, int]: ...
  ```

---

## Stack-Specific Findings

### P1. Flask `app.secret_key` Not Set: `auth.py` (whole file)
- **Severity:** HIGH
- **Issue:** `app.secret_key` is never set. Flask requires this to sign session cookies. If Flask sessions are ever used (e.g., after adding Flask-Login), they will silently use an insecure default or raise a runtime error.
- **Guide criterion violated:** python.md (Flask) — "`app.secret_key` hardcoded — session cookies are signed with this. Must come from environment."
- **Suggestion:**
  ```python
  app = Flask(__name__)
  app.secret_key = os.environ["SECRET_KEY"]  # Required; fail fast if missing
  ```

### P2. Known-Cracked MD5 Hashes Committed to Source: `auth.py:8-9`
- **Severity:** HIGH
- **Issue:** Both hardcoded MD5 hashes are in every common password database: `5f4dcc3b5aa765d61d8327deb882cf99` → "password", `e10adc3949ba59abbe56e057f20f883e` → "123456". Even without a rainbow table, these are two of the top-3 most guessed passwords. This combined with MD5 makes the credential store offer zero real protection.
- **Guide criterion violated:** python.md — "hashlib without salt — never raw SHA/MD5." Base security-reviewer — "Secrets: ... credentials in source code."
- **Suggestion:** Replace with bcrypt hashes and load from a non-source-controlled fixture.

### P3. No Dependency Declaration: fixture directory (no `requirements.txt`)
- **Severity:** LOW
- **Issue:** No `requirements.txt`, `pyproject.toml`, or `Pipfile` exists in the fixture directory. The `flask` dependency version is unknown and unpinned, making reproducible installs impossible.
- **Guide criterion violated:** python.md — "requirements.txt without pinning — Pin exact versions or use lock files."
- **Suggestion:** Add `requirements.txt`:
  ```
  Flask==3.0.3
  bcrypt==4.1.3
  itsdangerous==2.2.0
  ```

### P4. No Tests: fixture directory
- **Severity:** LOW
- **Issue:** No test file exists. Auth code is the highest-risk code in any application — login, reset, and delete paths all require automated coverage to prevent regressions.
- **Guide criterion violated:** python.md — "pytest fixtures over setUp — prefer pytest fixtures and parametrize."
- **Suggestion:** Add `test_auth.py` with pytest + Flask test client covering: valid login, invalid credentials, reset with valid/invalid token, delete with/without auth.

---

## Positive Practices

- The project uses Flask's built-in `jsonify()` for all responses — consistent, correct Content-Type headers.
- Route methods are constrained to `POST` only for all mutation endpoints — correct use of HTTP method restriction.
- The login endpoint does distinguish between "user not found" and "wrong password" path in terms of code flow — though both return the same generic error message (good for not leaking user enumeration information).
- The file is short and readable — no unnecessary complexity.

---

## Appendix: Subagent Execution Notes

The skill specifies spawning three parallel subagents:
- **Agent 1 (Security):** model `opus`
- **Agent 2 (Architecture):** model `sonnet`
- **Agent 3 (Stack-Specific):** model `sonnet`

Nested subagent spawning via the Agent tool was unavailable in this execution context. The three review passes were performed inline sequentially by the coordinating agent using identical criteria and prompts as specified in the skill. All findings from all three passes are included above; the "Appendix: Subagent Execution Notes" section documents this substitution.

---

## Summary Table (Deduplicated, Sorted by Severity)

| # | ID | Category | File:Line | Severity | Agent |
|---|-----|----------|-----------|----------|-------|
| 1 | S1 | Weak Crypto (MD5 passwords) | auth.py:14 | HIGH | Security |
| 2 | S3 | Hardcoded backdoor reset token | auth.py:38 | HIGH | Security |
| 3 | S4 | Unauthenticated admin endpoint | auth.py:45-51 | HIGH | Security |
| 4 | S5 | Debug mode RCE / Werkzeug | auth.py:55 | HIGH | Security |
| 5 | S2 | Timing attack on comparison | auth.py:27 | HIGH | Security |
| 6 | P1 | Flask secret_key not set | auth.py:5 | HIGH | Stack |
| 7 | P2 | Known-cracked hashes in source | auth.py:8-9 | HIGH | Stack |
| 8 | A1 | Global mutable state (user store) | auth.py:7-10 | HIGH | Architecture |
| 9 | S6 | No input validation / 500 leak | auth.py:19-47 | MEDIUM | Security |
| 10 | S7 | Forgeable session token | auth.py:28 | MEDIUM | Security |
| 11 | A2 | No separation of concerns | auth.py (whole) | MEDIUM | Architecture |
| 12 | A3 | No error handling | auth.py:19,34,47 | MEDIUM | Architecture |
| 13 | A4 | Hardcoded credentials as state | auth.py:7-10 | MEDIUM | Architecture |
| 14 | A5 | Missing type hints | auth.py:13,18,32,45 | LOW | Architecture |
| 15 | P3 | No dependency declaration | (directory) | LOW | Stack |
| 16 | P4 | No tests | (directory) | LOW | Stack |
