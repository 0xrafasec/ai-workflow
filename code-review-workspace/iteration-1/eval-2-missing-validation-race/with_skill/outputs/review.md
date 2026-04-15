# Code Review Report

**Stack:** Go (standard library, `net/http`, `os/exec`)
**Mode:** Full scan
**Branch:** 004-web-shell-mvp
**Date:** 2026-04-15

## Verdict: FAIL

| Metric | Value |
|--------|-------|
| Files reviewed | 1 (`counter.go`) |
| Security findings | 4 (3 HIGH, 1 MEDIUM) |
| Architecture findings | 4 (1 HIGH, 2 MEDIUM, 1 LOW) |
| Stack-specific findings | 4 (2 HIGH, 1 MEDIUM, 1 LOW) |

---

## Security Findings

### 1. Command Injection: `counter.go:22`
- **Severity:** HIGH
- **Confidence:** 10/10
- **Description:** User-supplied `req.Host` is concatenated directly into a shell command string passed to `exec.Command("sh", "-c", ...)`. Any attacker can inject arbitrary shell commands.
- **Guide criterion:** Go review guide — "os/exec with user input": use `exec.Command(binary, args...)` never `exec.Command("sh", "-c", userInput)`.
- **Fix:**
  ```go
  // Before (vulnerable)
  out, err := exec.Command("sh", "-c", "ping -c 1 "+req.Host).Output()

  // After (fixed) — pass host as a discrete argument, no shell interpolation
  if err := validateHost(req.Host); err != nil {
      http.Error(w, "invalid host", http.StatusBadRequest)
      return
  }
  out, err := exec.Command("ping", "-c", "1", req.Host).Output()
  ```
  Additionally, `validateHost` should reject inputs containing spaces, semicolons, pipes, backticks, `$`, `&`, `(`, `)`, newlines.

### 2. Cross-Site Scripting (XSS): `counter.go:37`
- **Severity:** HIGH
- **Confidence:** 10/10
- **Description:** `name` from the query string is concatenated raw into an HTML response. An attacker can inject arbitrary HTML/JavaScript via the `name` parameter.
- **Guide criterion:** Go review guide — "Template injection": use `html/template` for user-facing output, not string concatenation.
- **Fix:**
  ```go
  // Before (vulnerable)
  html := "<html><body>Hello, " + name + "</body></html>"
  w.Header().Set("Content-Type", "text/html")
  w.Write([]byte(html))

  // After (fixed)
  tmpl := template.Must(template.New("profile").Parse(
      `<html><body>Hello, {{.Name}}</body></html>`,
  ))
  w.Header().Set("Content-Type", "text/html")
  tmpl.Execute(w, struct{ Name string }{Name: name})
  ```
  Import `html/template` (not `text/template`).

### 3. Internal Error Leakage: `counter.go:24`
- **Severity:** HIGH
- **Confidence:** 9/10
- **Description:** `http.Error(w, err.Error(), 500)` sends the raw OS/exec error message to the client. This can disclose internal paths, binary names, system details, or partial command output.
- **Guide criterion:** Security reviewer base — "Data exposure: debug info in production".
- **Fix:**
  ```go
  // Before (leaks)
  http.Error(w, err.Error(), 500)

  // After
  log.Printf("ping error: %v", err)
  http.Error(w, "internal server error", http.StatusInternalServerError)
  ```

### 4. Missing HTTP Server Timeouts (DoS vector): `counter.go:46`
- **Severity:** MEDIUM
- **Confidence:** 9/10
- **Description:** `http.ListenAndServe(":8080", nil)` uses the default `http.Server` which has no read, write, or idle timeouts. Slow-loris and body-bomb attacks can exhaust server goroutines.
- **Guide criterion:** Go review guide — "Missing timeouts: `http.Server` without explicit timeouts = DoS vector."
- **Fix:**
  ```go
  // Before
  http.ListenAndServe(":8080", nil)

  // After
  srv := &http.Server{
      Addr:         ":8080",
      ReadTimeout:  5 * time.Second,
      WriteTimeout: 10 * time.Second,
      IdleTimeout:  120 * time.Second,
  }
  if err := srv.ListenAndServe(); err != nil {
      log.Fatal(err)
  }
  ```

---

## Architecture Findings

### 1. Race Condition on Global Variable: `counter.go:11,31`
- **Severity:** HIGH
- **Issue:** `counter` is a package-level `var int` mutated in `incrementHandler` without any synchronization. Concurrent HTTP requests will cause unsynchronized read-modify-write cycles, producing corrupted counter values and undefined behavior.
- **Guide criterion:** Go review guide — "Race conditions: shared state without mutex or channel synchronization."
- **Suggestion:**
  ```go
  // Replace the global var with an atomic or mutex-protected value
  import "sync/atomic"

  var counter int64

  func incrementHandler(w http.ResponseWriter, r *http.Request) {
      n := atomic.AddInt64(&counter, 1)
      w.Write([]byte(strings.Repeat("x", int(n))))
  }
  ```
  Or use `sync.Mutex` if the handler logic grows more complex.

### 2. Ignored Error Returns: `counter.go:18,20,27,46`
- **Severity:** MEDIUM
- **Issue:** Multiple error returns are silently discarded: `io.ReadAll` (line 18), `json.Unmarshal` (line 20), `w.Write` (lines 27, 32, 39), and `http.ListenAndServe` (line 46). Ignored errors mask malformed input, write failures, and server startup failures.
- **Guide criterion:** Go review guide — "Unchecked errors: every returned error must be checked."
- **Suggestion:**
  ```go
  // io.ReadAll
  body, err := io.ReadAll(r.Body)
  if err != nil {
      http.Error(w, "bad request", http.StatusBadRequest)
      return
  }

  // json.Unmarshal
  if err := json.Unmarshal(body, &req); err != nil {
      http.Error(w, "invalid JSON", http.StatusBadRequest)
      return
  }

  // ListenAndServe
  if err := srv.ListenAndServe(); err != nil {
      log.Fatal(err)
  }
  ```

### 3. No Input Validation on PingRequest.Host: `counter.go:13-15,19-20`
- **Severity:** MEDIUM
- **Issue:** The `PingRequest` struct has no validation. An empty, nil, or otherwise malformed `Host` field is accepted and forwarded to the shell command. There is no HTTP method check either — `pingHandler` will accept GET, POST, DELETE, etc.
- **Guide criterion:** Architecture reviewer base — "Error handling: validated at system boundaries (user input, external APIs)."
- **Suggestion:**
  ```go
  if req.Host == "" {
      http.Error(w, "host is required", http.StatusBadRequest)
      return
  }
  if r.Method != http.MethodPost {
      http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
      return
  }
  ```

### 4. Business Logic in `main` Package / No `cmd/` Convention: `counter.go:1`
- **Severity:** LOW
- **Issue:** All handler logic and the entry point live in `package main`. For any project that grows beyond a toy, this prevents reuse and testing. The Go convention places entry points in `cmd/<binary>/main.go` and business logic in separate packages.
- **Guide criterion:** Go review guide — "cmd/ convention: entry points in `cmd/<binary>/main.go`. Business logic should NOT live in `cmd/`."
- **Suggestion:** Refactor handlers into a separate `internal/handler` package; keep `main.go` minimal (wire up router, start server).

---

## Stack-Specific Findings

### 1. Shell Expansion via `"sh" "-c"` Pattern: `counter.go:22`
- **Severity:** HIGH
- **Issue:** `exec.Command("sh", "-c", ...)` is the single most dangerous pattern in Go HTTP handlers. It shells out to `/bin/sh` which performs word splitting, glob expansion, variable substitution, and command chaining on the combined string. This is redundant to the Security finding #1 but worth emphasizing as an idiomatic anti-pattern: Go does not need a shell intermediary to run `ping`.
- **Suggestion:** Use `exec.Command("ping", "-c", "1", host)` directly — no shell, no injection surface.

### 2. `html/template` vs String Concatenation for HTML: `counter.go:37`
- **Severity:** HIGH
- **Issue:** Raw string concatenation to build HTML responses is non-idiomatic Go and the root cause of the XSS finding. The `html/template` package is purpose-built for safe HTML generation.
- **Suggestion:** See Security Finding #2 above — replace with `html/template`.

### 3. `json.NewDecoder` Preferred over `io.ReadAll` + `json.Unmarshal`: `counter.go:18-20`
- **Severity:** MEDIUM
- **Issue:** The two-step `io.ReadAll` then `json.Unmarshal` pattern buffers the entire request body in memory before parsing. The idiomatic Go HTTP pattern streams directly:
- **Suggestion:**
  ```go
  var req PingRequest
  if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
      http.Error(w, "invalid request body", http.StatusBadRequest)
      return
  }
  ```
  Also add `r.Body = http.MaxBytesReader(w, r.Body, 1<<20)` before decoding to cap the body size.

### 4. Meaningless Response Body in `incrementHandler`: `counter.go:32`
- **Severity:** LOW
- **Issue:** `strings.Repeat("x", counter)` returns a string of N repeated `x` characters as the HTTP response. This is not a sensible API contract — the counter value itself (as JSON or plain text integer) should be returned. As the counter grows this also becomes a resource waste.
- **Suggestion:**
  ```go
  func incrementHandler(w http.ResponseWriter, r *http.Request) {
      n := atomic.AddInt64(&counter, 1)
      w.Header().Set("Content-Type", "application/json")
      fmt.Fprintf(w, `{"count":%d}`, n)
  }
  ```

---

## Positive Practices

- Package-level route registration using `http.HandleFunc` is correctly structured.
- Handler signatures correctly match `http.HandlerFunc` (`func(w http.ResponseWriter, r *http.Request)`).
- The code is concise and free of unnecessary abstractions, which simplifies the attack surface analysis.
- The use of a struct (`PingRequest`) for request deserialization is the right pattern — it just needs validation added.

---

## Appendix: Note on Parallel Subagents

The skill specification calls for spawning 3 parallel subagents (Security/opus, Architecture/sonnet, Stack-specific/sonnet). Nested subagent spawning was not available in this execution context. The three review passes were performed sequentially inline by the orchestrating agent, applying identical criteria from `agents/security-reviewer.md`, `agents/architecture-reviewer.md`, and `reviews/go.md`. All findings from all three passes are consolidated above without truncation.
