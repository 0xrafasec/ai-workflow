# Go Review Guide

Language-specific review criteria for Go projects. Load this alongside the base security-reviewer and architecture-reviewer agents.

---

## Security

### Error Handling
- **Unchecked errors** — every returned `error` must be checked. `_ = doSomething()` hiding errors is a finding.
- **Error wrapping** — use `fmt.Errorf("context: %w", err)` for traceability. Naked `return err` loses context.
- **Sensitive data in errors** — never wrap credentials, tokens, or PII into error messages. These end up in logs.

### Concurrency
- **Race conditions** — shared state without mutex or channel synchronization. Run `go vet -race` mentally on reviewed code.
- **Goroutine leaks** — goroutines blocked on channels that will never be written to/read from. Every goroutine must have a clear exit path.
- **Context cancellation** — long-running goroutines must respect `ctx.Done()`. Missing cancellation = resource leak under load.
- **sync.Pool misuse** — pooled objects must be fully reset before returning to pool. Residual data = information leak.

### Input & Injection
- **`os/exec` with user input** — any path from HTTP request to `exec.Command` is command injection. Use `exec.Command(binary, args...)` never `exec.Command("sh", "-c", userInput)`.
- **SQL injection** — use parameterized queries (`db.Query("SELECT ... WHERE id = $1", id)`). String concatenation into SQL is always a finding.
- **Template injection** — `text/template` does NOT escape HTML. Use `html/template` for any user-facing output.
- **Path traversal** — `filepath.Join` does NOT sanitize `..`. Always `filepath.Clean` + verify prefix after join.

### Crypto & Secrets
- **`math/rand` for security** — must use `crypto/rand` for tokens, keys, nonces. `math/rand` is predictable.
- **Hardcoded secrets** — flag any string literal that looks like a key, token, or password.
- **TLS config** — `InsecureSkipVerify: true` is always a finding in production code.

### HTTP
- **Missing timeouts** — `http.Server` and `http.Client` without explicit timeouts = DoS vector. Flag `&http.Client{}` with no `Timeout`.
- **Response body leaks** — `resp.Body` must be closed. `defer resp.Body.Close()` after error check.
- **CORS** — wildcard `Access-Control-Allow-Origin: *` with credentials is always wrong.

### Dependencies
- **CGo** — `import "C"` introduces memory safety issues. Flag and verify necessity.
- **`unsafe` package** — every usage needs justification. Pointer arithmetic bypasses Go's safety model.
- **Deprecated APIs** — `ioutil` package (deprecated in 1.16), `golang.org/x/crypto/ssh` with weak ciphers.

---

## Architecture

### Project Structure
- **Flat vs nested** — small projects should be flat. Flag unnecessary package nesting (e.g., `internal/pkg/utils/helpers/`).
- **Circular dependencies** — Go forbids them at compile time, but watch for design patterns that force awkward package splits.
- **`internal/` usage** — code that shouldn't be imported externally belongs in `internal/`.
- **`cmd/` convention** — entry points in `cmd/<binary>/main.go`. Business logic should NOT live in `cmd/`.

### Interface Design
- **Accept interfaces, return structs** — functions should accept the narrowest interface they need, return concrete types.
- **Interface bloat** — interfaces with 5+ methods are usually wrong. Go prefers small, composable interfaces (1-3 methods).
- **Interface in the consumer package** — define interfaces where they're used, not where they're implemented.
- **Empty interface abuse** — `interface{}` / `any` as a parameter type usually means the API design is wrong.

### Error Patterns
- **Sentinel errors** — use `var ErrNotFound = errors.New("not found")` for expected conditions. Don't compare error strings.
- **Error types** — use custom error types when callers need to extract information beyond the error message.
- **Panic usage** — `panic` is only acceptable in `init()` or truly unrecoverable situations. Never panic in library code.

### Concurrency Patterns
- **Channel ownership** — the goroutine that creates a channel should close it. Never close from the receiver side.
- **WaitGroup placement** — `wg.Add()` before launching the goroutine, `wg.Done()` with defer inside it.
- **Context propagation** — every function that does I/O or spawns goroutines should accept `context.Context` as first parameter.
- **errgroup over raw goroutines** — for fork-join patterns, `golang.org/x/sync/errgroup` handles error collection and cancellation.

### Testing
- **Table-driven tests** — standard Go pattern. Flag test files with many similar test functions that should be a table.
- **Test helpers** — use `t.Helper()` in helper functions for correct line reporting.
- **No `init()` in tests** — use `TestMain` for test setup/teardown.
- **Testable design** — if testing requires complex mocking, the design is probably wrong. Prefer dependency injection via interfaces.

### Performance Gotchas
- **String concatenation in loops** — use `strings.Builder`, not `+=`.
- **Large struct copies** — pass large structs by pointer. Flag pass-by-value for structs with 5+ fields.
- **Deferred close in loops** — `defer` in a loop defers until function return, not iteration end. Use a closure.
- **Slice preallocation** — when the size is known, use `make([]T, 0, n)` to avoid repeated growth.
