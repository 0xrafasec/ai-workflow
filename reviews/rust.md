# Rust Review Guide

Language-specific review criteria for Rust projects. Load this alongside the base security-reviewer and architecture-reviewer agents.

---

## Security

### Unsafe Code
- **Every `unsafe` block needs justification** — comment explaining why safe alternatives are insufficient. No blanket "performance" justifications without benchmarks.
- **`unsafe` audit scope** — the safety invariant must be maintained by the enclosing safe function. Callers must not be able to trigger UB through the safe API.
- **Raw pointer dereference** — verify the pointer is non-null, aligned, and points to valid memory for the type.
- **`unsafe impl Send/Sync`** — almost always wrong unless wrapping a C library with known thread safety. Flag and verify.
- **Mutable aliasing via unsafe** — two `&mut` references to the same data = instant UB. Check FFI boundaries carefully.

### FFI Boundaries
- **C string handling** — `CStr`/`CString` for C interop. Never transmute between `String` and C strings.
- **Null pointers from C** — always check for null before dereferencing pointers received from C. Use `NonNull` where possible.
- **Lifetime across FFI** — Rust lifetimes don't cross the FFI boundary. Verify that data outlives its usage on the C side.
- **Panic across FFI** — panicking across an FFI boundary is UB. Use `catch_unwind` at FFI entry points.

### Error Handling
- **`unwrap()` / `expect()` in library code** — flag all instances. Libraries must propagate errors, never panic on the caller's behalf.
- **`.unwrap()` on user input** — always a finding. External data must be validated with proper error handling.
- **`Result` vs `panic`** — `panic` is for programmer errors (invariant violations). Anything that depends on runtime input must return `Result`.

### Crypto & Secrets
- **Zeroing secrets** — use `zeroize` crate for sensitive data. Plain `drop()` doesn't guarantee memory clearing.
- **Constant-time comparison** — use `subtle::ConstantTimeEq` for comparing secrets. `==` leaks timing information.
- **RNG** — use `rand::rngs::OsRng` or `rand::thread_rng()` for cryptographic use. Never seed with predictable values.

### Input Handling
- **Integer overflow** — debug builds panic, release builds wrap. Use `checked_*`, `saturating_*`, or `wrapping_*` methods explicitly when overflow is possible from external input.
- **Index out of bounds** — prefer `.get()` over direct indexing when the index comes from external input.
- **Regex DoS** — the `regex` crate is safe (guaranteed linear time). But `fancy-regex` with backreferences is not.
- **Deserialization** — `serde` with untrusted input: set `#[serde(deny_unknown_fields)]`, use bounded containers, validate after deserialization.

### Dependencies
- **Dependency audit** — `cargo audit` should be part of CI. Flag `Cargo.toml` additions of unmaintained or low-download crates.
- **Feature flags** — unnecessary features can pull in vulnerable transitive deps. Use `default-features = false` and opt in.
- **Build scripts** — `build.rs` can execute arbitrary code at build time. Audit any new build script additions.

---

## Architecture

### Ownership & Lifetimes
- **Clone to escape borrow checker** — flag excessive `.clone()` calls. Usually means the data model or ownership structure needs rethinking.
- **Lifetime annotations** — complex lifetime signatures (`'a, 'b, 'c`) often indicate the API is fighting the borrow checker. Consider restructuring (owned data, arcs, indices).
- **`Rc`/`Arc` proliferation** — many shared references usually means the ownership model is unclear. Prefer clear ownership hierarchies.
- **Interior mutability** — `RefCell`/`Mutex` are tools, not defaults. Flag `RefCell` everywhere as a design smell.

### Type System
- **Newtype pattern** — domain concepts (UserId, Email, Port) should be newtypes, not raw primitives. Prevents mixing arguments.
- **Typestate pattern** — for state machines, use the type system to make invalid states unrepresentable (e.g., `Connection<Connected>` vs `Connection<Disconnected>`).
- **Enum vs trait objects** — prefer enums when variants are known at compile time. Trait objects for open extension.
- **`Box<dyn Error>` as catch-all** — acceptable in application code, not in library APIs. Libraries should define specific error types.

### Error Design
- **`thiserror` for libraries** — derive `Error` with structured variants. Each variant maps to a failure mode, not a source location.
- **`anyhow` for applications** — fine for binaries. Never use `anyhow` in library crate public APIs.
- **Error granularity** — one error enum per module/subsystem, not per function. But not one mega-enum for the whole crate either.

### Module Structure
- **`mod.rs` vs file-per-module** — Rust 2018+ prefers `foo.rs` + `foo/` directory over `foo/mod.rs`. Flag `mod.rs` in new code.
- **`pub` visibility** — default to private. Only mark `pub` what's part of the API. Flag `pub` on internal helpers.
- **Re-exports** — public API should be re-exported from `lib.rs`. Users shouldn't need to know your internal module structure.
- **Prelude modules** — only for crates with many commonly used types. Keep preludes small (5-10 items max).

### Async Patterns
- **Runtime choice** — don't mix `tokio` and `async-std`. Pick one and stick with it.
- **Blocking in async** — `std::fs`, `std::net`, CPU-heavy work in async context blocks the executor. Use `spawn_blocking` or async alternatives.
- **`Send` bounds** — futures that cross `.await` points with non-`Send` types can't be spawned on multi-threaded runtimes. Flag `Rc`, `RefCell` in async code.
- **Cancellation safety** — `select!` cancels the losing branch. If a future holds a lock or partial write, cancellation can corrupt state. Flag select over non-cancellation-safe futures.

### Testing
- **Unit tests in same file** — Rust convention: `#[cfg(test)] mod tests` at bottom of the file. Flag separate test files for unit tests.
- **Integration tests** — `tests/` directory for tests that use the public API only.
- **`#[should_panic]` vs `Result`** — prefer `-> Result<()>` in tests over `#[should_panic]` for better error messages.
- **Proptest/quickcheck** — for data structures and parsers, property-based testing catches edge cases unit tests miss.

### Performance Patterns
- **Allocation in hot paths** — flag `Vec::new()`, `String::new()`, `Box::new()` inside tight loops. Preallocate or reuse.
- **`collect()` vs iterators** — keep iterator chains lazy when possible. Don't `collect()` just to `iter()` again.
- **`Cow<str>`** — for functions that sometimes need to allocate and sometimes don't. Avoids unnecessary cloning.
- **`SmallVec`/`ArrayVec`** — for small, bounded collections that are usually stack-allocatable.
