# Known Gotchas — Index

Common issues and their solutions, split by category for targeted loading.

**AI agents:** Don't read this entire file for debugging. Use the routing below to load only the relevant gotcha file. Update the category files when you discover new issues.

## Routing

| Problem Area | File | When to load |
|---|---|---|
| **Rojo, Wally, Git** | [gotchas-tooling.md](gotchas-tooling.md) | Sync issues, package errors, project config, version control |
| **Runtime, replication, data** | [gotchas-runtime.md](gotchas-runtime.md) | Memory leaks, DataStore throttling, streaming, "works in Studio breaks in prod," deferred events |
| **Type checker, LSP, VS Code** | [gotchas-lsp.md](gotchas-lsp.md) | Type errors, LSP config, strict mode, sourcemaps |

## Quick Reference

If you're not sure which file to check, here's a keyword guide:

- **Rojo, sync, plugin, project.json, $ignoreUnknownInstances** → `gotchas-tooling.md`
- **Wally, packages, dependencies, realm, "Resolved 0"** → `gotchas-tooling.md`
- **Git, .rbxl, wally.lock, line endings** → `gotchas-tooling.md`
- **Memory leak, connection, GC, circular reference** → `gotchas-runtime.md`
- **DataStore, throttle, SetAsync, UpdateAsync, BindToClose** → `gotchas-runtime.md`
- **Streaming, StreamingEnabled, WaitForChild** → `gotchas-runtime.md`
- **Deferred, SignalBehavior, events not firing** → `gotchas-runtime.md`
- **Studio vs Live, "works in Studio"** → `gotchas-runtime.md`
- **Script timeout, infinite yield** → `gotchas-runtime.md`
- **Type error, luau-lsp, strict, sourcemap, .luaurc** → `gotchas-lsp.md`
- **Type solver, __call, coroutine.wrap warnings** → `gotchas-lsp.md`
