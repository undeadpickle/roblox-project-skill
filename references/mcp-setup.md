# Roblox Studio MCP Setup

MCP (Model Context Protocol) lets AI assistants like Claude directly interact with Roblox Studio—reading game structure, editing scripts, creating objects, and more.

## Options

### Option A: Community MCP (Recommended)

**boshyxd/robloxstudio-mcp** — Node.js-based, 18+ tools, active development.

**Features:**
- Read/edit scripts directly
- Create and modify objects
- Bulk property changes
- Project structure exploration
- Mass operations

**Setup:**

1. **Install the Studio plugin:**
   - Download from [GitHub releases](https://github.com/boshyxd/robloxstudio-mcp/releases)
   - Copy to your Plugins folder:
     - Windows: `%LOCALAPPDATA%\Roblox\Plugins\`
     - macOS: `~/Documents/Roblox/Plugins/`

2. **Enable HTTP requests in Studio:**
   - Game Settings → Security → Allow HTTP Requests → On

3. **Add to Claude Code:**
   ```bash
   claude mcp add robloxstudio -- npx -y robloxstudio-mcp
   ```

   Or add to MCP config manually:
   ```json
   {
     "mcpServers": {
       "robloxstudio-mcp": {
         "command": "npx",
         "args": ["-y", "robloxstudio-mcp"]
       }
     }
   }
   ```

4. **Verify connection:**
   - Open Studio with a place
   - Plugin should show "Connected"
   - In Claude, MCP tools should appear

### Option B: Official Roblox MCP

**Roblox/studio-rust-mcp-server** — Rust-based, official but limited (2 tools: `insert_model`, `run_code`).

**Setup:**

1. **Prerequisites:**
   - Rust installed
   - Roblox Studio installed and opened once
   - Claude Desktop installed and opened once

2. **Build and install:**
   ```bash
   git clone https://github.com/Roblox/studio-rust-mcp-server.git
   cd studio-rust-mcp-server
   cargo run
   ```
   
   This builds the server, installs the Claude config, and installs the Studio plugin.

3. **Verify:**
   - Studio: Plugins tab → MCP plugin should appear
   - Claude Desktop: Hammer icon should show `insert_model` and `run_code` tools

**Manual config (if needed):**
```json
{
  "mcpServers": {
    "Roblox Studio": {
      "command": "/path/to/rbx-studio-mcp",
      "args": ["--stdio"]
    }
  }
}
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Plugin not showing | Restart Studio, check Plugins folder path |
| "Not connected" | Enable HTTP Requests in Game Settings → Security |
| Tools not appearing in Claude | Restart Claude, check MCP config syntax |
| Commands failing | Ensure a place is open in Studio |

## Security Notes

- MCP allows AI to read and modify your open place
- Only enable when actively using AI assistance
- Toggle plugin off when not needed
- Review any actions before confirming in Claude

## Which to Choose?

| Need | Choose |
|------|--------|
| Script editing, bulk operations | Community (Option A) |
| Simple model insertion, code execution | Official (Option B) |
| Easiest setup | Community (npx install) |
| Minimal dependencies | Official (if Rust already installed) |

For most developers, **Option A (Community MCP)** provides the best experience with more tools and easier setup.
