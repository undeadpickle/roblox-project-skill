# Roblox MCP Server Setup

MCP (Model Context Protocol) servers let Claude see and interact with Roblox Studio directly. Studio must be open for either to work.

## Available MCP Servers

| Server | Purpose | Tools |
|--------|---------|-------|
| **Official Roblox MCP** | Run Luau code, insert models | `run_code`, `insert_model` |
| **boshyxd MCP** | Read scripts, bulk operations, project analysis | 18+ tools |
| **Context7** | Live Roblox documentation lookup | `resolve-library-id`, `query-docs` |

**Recommendation:** Start with the Official MCP—it covers most use cases. Add boshyxd later if you need script reading or bulk operations. Context7 is useful for API lookups without leaving the editor.

---

## Official Roblox MCP (Recommended)

### Step 1: Download the App

Download from [GitHub releases](https://github.com/Roblox/studio-rust-mcp-server/releases):
- macOS: `macOS-rbx-studio-mcp.zip`
- Windows: `rbx-studio-mcp.exe`

### Step 2: Move to a Global Location

**Important:** Don't leave it in a random project folder. Move it somewhere permanent:

**macOS:**
```bash
# Unzip first if needed, then:
mv ~/Downloads/RobloxStudioMCP.app /Applications/
```

**Windows:**
```
Move to: C:\Program Files\RobloxStudioMCP\
```

### Step 3: Add to Claude Code

**macOS:**
```bash
claude mcp add roblox-studio -- "/Applications/RobloxStudioMCP.app/Contents/MacOS/rbx-studio-mcp" --stdio
```

**Windows:**
```bash
claude mcp add roblox-studio -- "C:\Program Files\RobloxStudioMCP\rbx-studio-mcp.exe" --stdio
```

### Step 4: Restart & Verify

1. Restart VS Code
2. Open Roblox Studio with a place
3. Check Studio's Output window for: `"The MCP Studio plugin is ready for prompts"`
4. In Claude Code, run: `claude mcp list` — should show `roblox-studio: ✓ Connected`

---

## boshyxd MCP (Optional)

Adds more tools for reading scripts, searching objects, and bulk operations.

### Step 1: Check Your npx Path

**Critical for NVM users:** Claude Code spawns MCP servers in a clean environment that doesn't load your shell profile, so `npx` won't resolve.

```bash
which npx
```

Example output: `/Users/yourname/.nvm/versions/node/v22.13.1/bin/npx`

### Step 2: Add to Claude Code

**If using NVM (use full path):**
```bash
claude mcp add robloxstudio -e ROBLOX_STUDIO_PORT=3003 -- /Users/yourname/.nvm/versions/node/v22.13.1/bin/npx -y robloxstudio-mcp@latest
```

**If npx is in standard PATH:**
```bash
claude mcp add robloxstudio -e ROBLOX_STUDIO_PORT=3003 -- npx -y robloxstudio-mcp@latest
```

> **Why port 3003?** Avoids conflict with the official MCP if running both.

### Step 3: Install Studio Plugin

1. In Studio: Plugins tab → Manage Plugins → Search "MCP" (or get from Creator Store)
2. Game Settings → Security → Enable **"Allow HTTP Requests"**
3. Click MCP plugin icon → Set Server URL to `http://localhost:3003`
4. Click Connect

### Step 4: Restart & Verify

1. Restart VS Code
2. Health check:
   ```bash
   curl -s http://localhost:3003/health
   ```

   Healthy response:
   ```json
   {"pluginConnected":true,"mcpServerActive":true}
   ```

---

## Running Both Servers

You can run both simultaneously:

| Server | Port | Tools Prefix |
|--------|------|--------------|
| Official | (stdio) | `mcp__roblox-studio__` |
| boshyxd | 3003 | `mcp__robloxstudio__` |

---

## Troubleshooting

### "Failed" status but server is running

This happens when an existing server process is holding the port, preventing Claude Code from spawning its own.

```bash
# Kill existing processes
lsof -ti :3003 | xargs kill 2>/dev/null

# Restart VS Code
```

### NVM: "npx not found" or MCP fails to start

Claude Code doesn't load your `.zshrc`/`.bashrc`, so NVM's npx isn't in PATH.

**Fix:** Use the full path to npx (see Step 1 of boshyxd setup).

### Port already in use

```bash
# Find what's using the port
lsof -i :3003

# Kill it
lsof -ti :3003 | xargs kill
```

### Plugin stuck on "Retrying"

1. Restart VS Code (this restarts the MCP server)
2. Reconnect the Studio plugin

### Tools work then stop after Studio restart

The Studio plugin disconnects when you close/reopen Studio. Just reconnect the plugin.

### Official MCP: No plugin visible in Studio

The plugin auto-installs when you first run the MCP. If missing:
1. Close Studio
2. Run the MCP app manually once
3. Reopen Studio

---

## Quick Reference

| Task | Server | Command/Tool |
|------|--------|--------------|
| Run Luau code in Studio | Official | `run_code` |
| Insert marketplace model | Official | `insert_model` |
| Get project hierarchy | boshyxd | `get_project_structure` |
| Search objects by name/class | boshyxd | `search_objects` |
| Read script source | boshyxd | `get_script_source` |
| Bulk property changes | boshyxd | `mass_set_property` |
| Look up Roblox API docs | Context7 | `query-docs` |
| Find library ID for docs | Context7 | `resolve-library-id` |

---

## Context7 MCP (Documentation)

Context7 provides live documentation lookup—no need to leave the editor or search the web.

### Step 1: Get API Key

Sign up at [context7.com](https://context7.com) and get your API key.

### Step 2: Add to Claude Code

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
```

### Step 3: Restart & Verify

1. Restart VS Code
2. Ask Claude to look up Roblox docs
3. Should see `context7` in `/mcp` status

### Roblox Library IDs

Use these when querying:
- `/websites/create_roblox` — Tutorials, guides, best practices (22k+ snippets)
- `/websites/create_roblox_reference_engine` — Engine API reference (7k+ snippets)

### Fallback (No Context7)

If Context7 is unavailable or you're out of credits, use WebSearch/WebFetch with these URLs:
- **Engine API:** https://create.roblox.com/docs/reference/engine
- **Guides & Tutorials:** https://create.roblox.com/docs
- **Tip:** Add `site:create.roblox.com` to WebSearch queries for official docs only

---

## Security Notes

- MCP allows AI to read and modify your open place
- Only enable when actively using AI assistance
- Review actions before confirming
- The official MCP shows a warning: *"This MCP server will be accessed by third-party tools, allowing them to modify and read the contents of your opened place."*
