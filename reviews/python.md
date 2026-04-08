# Python Review Guide

Language-specific review criteria for Python projects — covering Flask, FastAPI, Django, and general Python. Load this alongside the base security-reviewer and architecture-reviewer agents.

---

## Security

### Injection
- **`eval()`, `exec()`, `compile()`** — with any user-influenced input is always a finding. No exceptions.
- **`os.system()`, `subprocess.call(shell=True)`** — command injection. Use `subprocess.run()` with argument lists and `shell=False`.
- **f-string SQL** — `f"SELECT * FROM users WHERE id = {id}"` is SQL injection. Use parameterized queries (SQLAlchemy bind params, Django ORM, psycopg2 `%s` placeholders).
- **`pickle.loads()` on untrusted data** — arbitrary code execution. Use JSON, msgpack, or protobuf for untrusted input.
- **`yaml.load()` without `Loader`** — use `yaml.safe_load()`. The default loader allows arbitrary Python object construction.
- **Jinja2 `| safe` filter** — disables autoescaping. Flag any usage with user-provided content.
- **`__import__()` with user input** — module injection. Never dynamically import based on user input.

### Path Traversal
- **`open(user_input)`** — must validate the resolved path stays within expected directory. Use `pathlib.Path.resolve()` + check `is_relative_to()`.
- **`os.path.join()` with absolute user input** — `os.path.join("/uploads", "/etc/passwd")` returns `/etc/passwd`. Always validate after joining.
- **`send_file()` / `send_from_directory()`** — Flask's `send_from_directory` is safe. `send_file(user_input)` is not.

### Auth & Sessions
- **Django `SECRET_KEY` in source** — must come from environment. Flag hardcoded values.
- **`@login_required` missing** — every Django view that needs auth must have the decorator or use a mixin.
- **FastAPI dependency injection for auth** — use `Depends(get_current_user)` not manual token parsing in each route.
- **CORS wildcard** — `allow_origins=["*"]` with `allow_credentials=True` is always wrong.

### Crypto & Secrets
- **`random` for security** — use `secrets` module for tokens, keys, nonces. `random` is predictable.
- **`hashlib` without salt** — password hashing must use `bcrypt`, `argon2`, or `scrypt`. Never raw SHA/MD5.
- **Timing attacks** — use `hmac.compare_digest()` for comparing secrets. `==` leaks timing information.

### Dependencies
- **`requirements.txt` without pinning** — `requests>=2.0` pulls latest. Pin exact versions or use lock files.
- **`setup.py` with `os.system()`** — arbitrary code execution on install. Audit any new dependency's setup.py.
- **Typosquatting** — verify package names carefully (`python-dateutil` not `dateutil`, `Pillow` not `PIL`).

### Framework-Specific

#### Django
- **`DEBUG = True` in production** — leaks settings, SQL queries, stack traces.
- **`ALLOWED_HOSTS = ['*']`** — host header injection. Must be explicit.
- **Raw SQL** — `Model.objects.raw()` and `cursor.execute()` with string formatting = SQL injection.
- **`|safe` template filter** — same as Jinja2, disables autoescaping.
- **CSRF exemption** — `@csrf_exempt` must be justified. Usually indicates API endpoints that need proper token auth instead.
- **Mass assignment** — `ModelForm` without explicit `fields` or `exclude` exposes all model fields.

#### FastAPI
- **Missing response model** — endpoints without `response_model` can leak internal fields. Always define what's returned.
- **Pydantic `model_validate` on untrusted data** — safe for type coercion, but custom validators can have side effects. Audit validators.
- **Background tasks with request state** — `BackgroundTasks` run after response. Don't pass database sessions that might be closed.
- **WebSocket auth** — WebSocket connections don't go through regular middleware. Auth must be checked explicitly on connect.

#### Flask
- **`app.secret_key` hardcoded** — session cookies are signed with this. Must come from environment.
- **`request.args.get()` without validation** — type coercion is implicit. Always validate and cast explicitly.
- **Debug mode** — `app.run(debug=True)` in production exposes the Werkzeug debugger (RCE).

---

## Architecture

### Project Structure
- **Flat vs packages** — small projects can be flat. Flag unnecessary nesting (e.g., `src/utils/helpers/common/`).
- **Circular imports** — Python allows them sometimes but they're always a design smell. Restructure.
- **`__init__.py` bloat** — keep `__init__.py` for re-exports only. No business logic.
- **Settings module** — one place for configuration (`settings.py`, `config.py`). Not scattered `os.getenv()` calls.

### Type Hints
- **Missing type hints on public functions** — all public API functions should have type annotations.
- **`Any` usage** — same as TypeScript `any`. Every `Any` needs justification.
- **`# type: ignore`** — each suppression needs a comment explaining why. Blanket suppression is a finding.
- **Runtime validation** — types are NOT runtime checks. External data must be validated with Pydantic, attrs, or manual checks.

### Error Handling
- **Bare `except:`** — catches `SystemExit`, `KeyboardInterrupt`, everything. At minimum use `except Exception:`.
- **Silenced exceptions** — `except: pass` hides bugs. Always log or re-raise.
- **Exception hierarchy** — define domain exceptions inheriting from a base. Don't raise `ValueError` for business logic errors.
- **Return None vs raise** — prefer raising exceptions for error conditions. `Optional` returns are for "might not exist" semantics.

### Async Patterns (asyncio)
- **Blocking in async** — `time.sleep()`, synchronous I/O in async functions blocks the event loop. Use `asyncio.sleep()`, `aiofiles`, `httpx`.
- **`asyncio.run()` in wrong context** — can't call `asyncio.run()` inside an already-running loop. Use `await` directly.
- **Task cancellation** — `asyncio.Task.cancel()` raises `CancelledError`. Ensure cleanup with `try/finally`.
- **Sync ↔ async bridge** — use `run_in_executor()` for CPU-bound or legacy sync code in async context.

### Testing
- **pytest fixtures over setUp** — prefer pytest fixtures and parametrize over unittest-style setUp/tearDown.
- **Factory pattern** — use `factory_boy` or custom factories. Not hardcoded test data.
- **Mocking boundaries** — mock at the boundary (API calls, database), not internal functions. Use `responses` or `httpx.MockTransport`.
- **`conftest.py` scope** — keep conftest.py files in the right directory scope. Root conftest for shared fixtures, subdirectory for specific ones.

### Django Specific
- **Fat models** — business logic in models, not views. Views are thin dispatchers.
- **Manager methods** — complex querysets belong in custom managers, not scattered across views.
- **Signals overuse** — signals make control flow implicit. Prefer explicit method calls unless truly decoupled.
- **Migration squashing** — projects with 100+ migrations should squash periodically.

### FastAPI Specific
- **Dependency injection** — use `Depends()` for shared logic (auth, db sessions, config). Don't instantiate in route functions.
- **Router organization** — one router per domain (users, auth, orders). Don't put everything in `main.py`.
- **Middleware vs dependencies** — middleware for cross-cutting concerns (logging, CORS). Dependencies for route-specific needs.
- **Async all the way** — if using async, keep the full call chain async. One sync call in the chain blocks the whole thing.

### Performance
- **N+1 queries** — Django: use `select_related()` / `prefetch_related()`. SQLAlchemy: use `joinedload()` / `selectinload()`.
- **List comprehension vs generator** — for large datasets, use generators. Don't materialize million-row lists.
- **Global mutable state** — module-level mutable variables are shared across requests in WSGI/ASGI. Use request-scoped state.
- **Connection pooling** — ensure database connections are pooled (SQLAlchemy `pool_size`, Django `CONN_MAX_AGE`).
