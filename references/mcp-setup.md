# Roblox MCP Server Setup

MCP (Model Context Protocol) servers let Claude see and interact with Roblox Studio directly. Studio must be open for either to work.

## Available MCP Servers

| Server | Purpose | Port |
|--------|---------|------|
| **Official Roblox MCP** | Run Luau code, insert models | 3002 |
| **boshyxd MCP** | Read scripts, bulk operations, project analysis | 3003 |

Both can run simultaneously on different ports.

## Setup

### Official Roblox MCP

```bash
claude mcp add roblox-studio -- "/path/to/RobloxStudioMCP.app/Contents/MacOS/rbx-studio-mcp" --stdio
```

Replace `/path/to/` with actual install location.

### boshyxd MCP

```bash
claude mcp add robloxstudio -e ROBLOX_STUDIO_PORT=3003 -- npx -y robloxstudio-mcp@latest
```

**If using NVM**, use full path to npx:
```bash
claude mcp add robloxstudio -e ROBLOX_STUDIO_PORT=3003 -- /path/to/.nvm/versions/node/vX.X.X/bin/npx -y robloxstudio-mcp@latest
```

Find your npx path with: `which npx`

### boshyxd Studio Plugin

1. Install from Roblox Creator Store OR download MCPPlugin.rbxmx
2. In Studio: Game Settings → Security → Enable "Allow HTTP Requests"
3. Click plugin icon, set Server URL to `http://localhost:3003`
4. Click Connect

## When to Use Which

**Official MCP** (`mcp__roblox-studio__*`):
- Running Luau code directly in Studio
- Inserting models from marketplace
- Quick create/modify operations via code execution

**boshyxd MCP**:
- Project structure analysis (`get_project_structure`, `get_file_tree`)
- Reading script source without execution
- Searching objects by name/class/property
- Bulk operations (`mass_set_property`, `mass_create_objects`)
- Getting detailed instance properties

## Tool Reference

| Task | Server | Tool/Endpoint |
|------|--------|---------------|
| Run Luau code | Official | `run_code` |
| Insert marketplace model | Official | `insert_model` |
| Get project hierarchy | boshyxd | `get_project_structure` |
| Search objects | boshyxd | `search_objects` |
| Read script source | boshyxd | `get_script_source` |
| Edit script lines | boshyxd | `edit_script_lines` |
| Bulk property changes | boshyxd | `mass_set_property` |
| Create objects with props | boshyxd | `create_object_with_properties` |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Failed to connect" | Kill stale processes: `lsof -ti :3002 :3003 \| xargs kill` |
| "Port already in use" | Another process on port; kill it or change port |
| Plugin stuck on "Retrying" | Restart VS Code, then reconnect plugin |
| boshyxd tools not responding | Ensure Studio plugin connected to correct port |
| Tools work then stop after Studio restart | Restart VS Code to restart MCP server |

### Health Check (boshyxd)

```bash
curl -s http://localhost:3003/health
```

Healthy response:
```json
{"status":"ok","pluginConnected":true,"mcpServerActive":true}
```

If `mcpServerActive: false`: Restart VS Code, reconnect Studio plugin.

## Key Setup Notes

- Set `ROBLOX_STUDIO_PORT=3003` for boshyxd to avoid port conflict with official MCP
- Restart VS Code after MCP config changes
- Studio must be open before MCP tools will work
- boshyxd requires the Studio plugin; official MCP does not
