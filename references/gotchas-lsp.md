# Gotchas: Type Checking & Luau LSP

Issues with the Luau language server, type checker, and VS Code integration.

**AI agents:** Update this file when you discover LSP configuration issues or type solver quirks.

---

## Deprecated: `luau-lsp.types.roblox`

The old setting `luau-lsp.types.roblox: true` shows a deprecation warning. Use the new setting:

```json
// ❌ Deprecated
{
  "luau-lsp.types.roblox": true
}

// ✅ Current
{
  "luau-lsp.platform.type": "roblox"
}
```

## New Type Solver (Default as of Nov 2025)

Roblox's new type solver is now **out of beta and enabled by default**. Some patterns that worked before may show warnings:
- `__call` metamethods may cause "Cannot call non-function" warnings
- `coroutine.wrap` iterators may show "next() does not return enough values"
- Some generic type inference behaves differently

**Workarounds:**
- Use `:: any` type assertions for problematic patterns
- Toggle solver in Studio: File → Studio Settings → Script Analysis → Type Check Mode
- The new solver is stricter but catches more real bugs — worth adapting to

## Project-level strict vs per-file strict

Two common patterns:

**Pattern A: Global strict (recommended for new projects)**
```json
// .luaurc
{
  "languageMode": "strict"
}
```

**Pattern B: Opt-in strict (for existing projects)**
```json
// .luaurc
{
  "languageMode": "nonstrict"
}
```
Then add `--!strict` to files that benefit from it.

## Luau LSP not showing DataModel types

Enable sourcemap generation in VS Code settings:

```json
{
  "luau-lsp.sourcemap.enabled": true,
  "luau-lsp.sourcemap.rojoProjectFile": "default.project.json"
}
```

## "Unknown require" warnings

Ensure `.luaurc` has aliases matching your project:

```json
{
  "aliases": {
    "Packages": "Packages"
  }
}
```
