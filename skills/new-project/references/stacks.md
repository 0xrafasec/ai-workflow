# Stack reference

Per-stack choices for the Makefile, the pre-commit config and CLAUDE.md. Use the row for the chosen stack; for a stack not listed, pick the community-standard test runner and linter and tell the user what you chose.

| Stack | test | lint | typecheck | build | lint-changed |
|-------|------|------|-----------|-------|--------------|
| python | `pytest` | `ruff check .` and `ruff format --check .` | `mypy .` (or `pyright`) | - | `git diff --name-only --diff-filter=d HEAD -- '*.py'` piped to `xargs -r ruff check` |
| go | `go test ./...` | `go vet ./...` and `golangci-lint run` | built in (`go vet`) | `go build ./...` | `golangci-lint run --new-from-rev=HEAD` |
| typescript | `vitest run` | `eslint .` | `tsc --noEmit` | the framework's own (`next build`, `tsc`) | `git diff --name-only --diff-filter=d HEAD -- '*.ts' '*.tsx'` piped to `xargs -r eslint` |
| rust | `cargo test` | `cargo clippy -- -D warnings` and `cargo fmt --check` | built in | `cargo build` | same as `lint` (cargo has no per-file mode) |

## Notes

- `ruff` replaces black, flake8 and isort; do not add them. Python config goes in `pyproject.toml` under `[tool.ruff]` and `[tool.pytest.ini_options]`.
- `golangci-lint` v2 requires `version: "2"` at the top of `.golangci.yml`; omit the file unless a setting is needed.
- `lint-changed` must exit 0 when no matching file changed and when the repo has no commits yet (`git diff HEAD` fails then); guard with `git rev-parse --verify HEAD >/dev/null 2>&1 || exit 0` and add untracked files via `git ls-files --others --exclude-standard`.
- Pre-commit hooks per stack: python `ruff-pre-commit` (ids `ruff`, `ruff-format`), go `golangci-lint`, typescript a local `eslint` hook, rust local `cargo fmt --check` and `cargo clippy` hooks. Each repo's `rev` comes from `git ls-remote --tags <repo>`.
- Add a security scanner (`bandit`, `gosec`) only if the user asks; gitleaks already covers secrets.
- If a CLI's flags are in doubt, check `<tool> --help` before writing them into the Makefile.
