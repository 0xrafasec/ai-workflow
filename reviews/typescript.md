# TypeScript Review Guide

Language-specific review criteria for TypeScript projects — covering Node.js, Next.js, and Nest.js. Load this alongside the base security-reviewer and architecture-reviewer agents.

---

## Security

### Common (All TypeScript)

#### Injection
- **`eval()`, `new Function()`, `vm.runInNewContext()`** — with any user-influenced input is always a finding.
- **Template literal SQL** — `` `SELECT * FROM users WHERE id = ${id}` `` is SQL injection. Use parameterized queries (Prisma, Knex, TypeORM query builder).
- **`child_process.exec()` with user input** — command injection. Use `execFile()` or `spawn()` with argument arrays.
- **`innerHTML`, `dangerouslySetInnerHTML`** — XSS vector. Flag any usage with data that isn't compile-time static.
- **Regex with user input** — `new RegExp(userInput)` is ReDoS. Use a regex-safe library or validate input first.

#### Prototype Pollution
- **Deep merge / extend** — `Object.assign()`, lodash `_.merge()`, spread with untrusted input can pollute `__proto__`. Use `Object.create(null)` as base or validate keys.
- **JSON.parse without validation** — parsed objects can contain `__proto__` keys. Validate with Zod/Joi after parsing.

#### Auth & Sessions
- **JWT in localStorage** — XSS can steal tokens. Use httpOnly cookies for session tokens.
- **Missing `sameSite` on cookies** — default `sameSite: 'Lax'` minimum. `'None'` requires `Secure`.
- **Algorithm confusion in JWT** — always specify algorithm in `verify()`, never trust the token header.
- **Timing-safe comparison** — use `crypto.timingSafeEqual()` for comparing secrets, tokens, HMAC signatures.

#### Secrets & Config
- **Hardcoded secrets in source** — API keys, database URLs, tokens in source files. Must come from environment.
- **`.env` committed** — verify `.env` is in `.gitignore`. Flag if committed.
- **Logging secrets** — `console.log(req.headers)` can leak auth tokens. Flag logging of full headers or request objects.

#### Dependencies
- **Prototype pollution in deps** — check `npm audit` / `pnpm audit` regularly.
- **Postinstall scripts** — `package.json` `postinstall` can execute arbitrary code. Audit new dependencies.
- **`node_modules` in Docker** — never `COPY node_modules`. Always `RUN npm ci` in the image.

### Node.js Specific

- **Path traversal** — `path.join('/uploads', userInput)` doesn't prevent `../`. Always `path.resolve()` + verify result starts with expected prefix.
- **Stream backpressure** — piping without handling backpressure = memory exhaustion. Use `pipeline()` from `stream/promises`.
- **Unhandled promise rejections** — Node 15+ crashes on unhandled rejections. Ensure all promises have catch handlers or use `process.on('unhandledRejection')`.
- **Event emitter memory leaks** — more than 10 listeners on an emitter triggers a warning for good reason. Flag `setMaxListeners(0)`.
- **`Buffer` from user input** — `Buffer.allocUnsafe()` can leak memory. Use `Buffer.alloc()` for buffers that might be partially filled.

### Next.js Specific

- **Server Actions** — `"use server"` functions are public API endpoints. They MUST validate input and check auth. Treat them like route handlers.
- **Server Component data leaks** — data fetched in server components can end up in the client bundle if passed as props carelessly. Check the RSC payload.
- **`getServerSideProps` / route handlers without auth** — every server-side data fetch must verify the user has access to the requested resource.
- **Middleware auth bypass** — Next.js middleware runs on the Edge runtime. Ensure auth checks can't be bypassed by direct API route access.
- **Environment variables** — only `NEXT_PUBLIC_*` vars are exposed to the client. Flag any sensitive var with that prefix.
- **`revalidatePath`/`revalidateTag` abuse** — cache invalidation can be triggered by unauthorized users if the server action isn't protected.
- **Image optimization SSRF** — `next/image` with `remotePatterns` set to wildcard can be used for SSRF. Restrict domains.

### Nest.js Specific

- **Missing guards on controllers** — every controller or route that needs auth must have `@UseGuards()`. Flag unprotected endpoints.
- **Global vs scoped guards** — prefer global guards with explicit `@Public()` decorator on open routes over per-route guards (easy to forget).
- **DTO validation** — use `class-validator` + `class-transformer` with `ValidationPipe`. Flag controllers accepting raw `@Body()` without validation.
- **Circular dependency injection** — `forwardRef()` is a code smell. Usually means modules are too tightly coupled.
- **Exposed internal errors** — default Nest exception filter leaks stack traces. Ensure custom exception filters are in place for production.
- **TypeORM/Prisma raw queries** — same SQL injection risks. Flag any `.query()` or `$queryRaw` with string interpolation.

---

## Architecture

### Common (All TypeScript)

#### Type Safety
- **`any` usage** — every `any` needs justification. Prefer `unknown` for truly unknown types, then narrow.
- **Type assertions (`as`)** — `value as Type` bypasses checking. Flag excessive use. Prefer type guards.
- **`!` non-null assertion** — hides potential null errors. Use optional chaining or proper null checks.
- **Implicit `any`** — ensure `strict: true` and `noImplicitAny` in `tsconfig.json`.
- **Zod/Joi at boundaries** — external data (API responses, user input, env vars) must be runtime-validated, not just typed.

#### Async Patterns
- **Missing `await`** — calling async function without `await` silently swallows errors. ESLint `@typescript-eslint/no-floating-promises` should catch this.
- **Sequential awaits that could be parallel** — `await a(); await b()` when independent should be `await Promise.all([a(), b()])`.
- **Error handling in async** — `try/catch` around `await` or `.catch()` on the promise. Not both, and not neither.
- **Async in forEach** — `array.forEach(async ...)` doesn't await. Use `for...of` or `Promise.all(array.map(...))`.

#### Module Design
- **Barrel files** — `index.ts` re-exports can cause circular dependency issues and slow builds. Keep them thin or avoid.
- **Side effects on import** — module-level code that runs on import (database connections, API calls) makes testing hard and causes ordering bugs.
- **Dependency direction** — higher-level modules should depend on lower-level ones. Never import from `routes/` into `models/`.

### Node.js Specific

- **Error handling middleware** — Express/Fastify need a centralized error handler. Don't catch and swallow in individual routes.
- **Graceful shutdown** — handle `SIGTERM`/`SIGINT`. Close database connections, finish in-flight requests, then exit.
- **Environment configuration** — validate all env vars at startup (with Zod), fail fast on missing config.

### Next.js Specific

- **Client vs Server boundary** — minimize `"use client"` directives. Push them as far down the component tree as possible.
- **Data fetching strategy** — server components for data fetching, client components for interactivity. Don't fetch in client components when server components can.
- **Route segment config** — `dynamic`, `revalidate`, `runtime` exports must match the route's needs. Flag `export const dynamic = 'force-dynamic'` without justification.
- **Parallel routes and intercepting routes** — powerful but complex. Ensure the mental model is clear and documented.
- **API routes vs server actions** — prefer server actions for mutations from React. API routes for external consumers.

### Nest.js Specific

- **Module boundaries** — each module should have a clear responsibility. Flag modules with 10+ providers.
- **Provider scope** — default singleton. Use `REQUEST` scope only when needed (it has performance implications).
- **Repository pattern** — data access through repositories, not direct ORM calls in services.
- **Interceptors vs middleware vs guards** — each has a specific purpose. Guards for auth, interceptors for transformation/logging, middleware for raw request processing.
- **Circular modules** — `forwardRef(() => Module)` between modules means the boundary is wrong. Refactor into a shared module.
- **Event-driven decoupling** — use `@nestjs/event-emitter` for cross-module communication instead of direct imports.

### Testing

- **Test boundaries** — unit tests mock external deps. Integration tests use real deps. Don't mix.
- **Snapshot testing** — only for stable, visual output (component renders). Never for API responses or data structures (brittle).
- **Test data factories** — use factories (fishery, @faker-js/faker) not hardcoded fixtures. Reduces test coupling.
- **MSW for API mocking** — `msw` intercepts at the network level. Better than mocking fetch/axios (tests more of the real code).
