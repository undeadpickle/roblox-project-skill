#!/bin/bash
#
# Smoke Test for Roblox Development Skill
# Runs quick checks to verify the skill is set up correctly.
#
# Usage: ./scripts/smoke-test.sh
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0
WARN=0

# Get script directory (works even if called from different location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo ""
echo "========================================"
echo "  Roblox Skill Smoke Test"
echo "========================================"
echo ""

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    echo -e "  ${RED}→ $2${NC}"
    ((FAIL++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    echo -e "  ${YELLOW}→ $2${NC}"
    ((WARN++))
}

# ----------------------------------------
# 1. Core Skill Files
# ----------------------------------------
echo "Core Files"
echo "----------"

if [ -f "$PROJECT_ROOT/SKILL.md" ]; then
    pass "SKILL.md exists"
else
    fail "SKILL.md missing" "This is the main skill file Claude reads"
fi

if [ -f "$PROJECT_ROOT/VERSION" ]; then
    VERSION=$(cat "$PROJECT_ROOT/VERSION" | tr -d '[:space:]')
    if [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        pass "VERSION file valid ($VERSION)"
    else
        fail "VERSION format invalid" "Expected format: X.Y.Z (e.g., 1.0.0)"
    fi
else
    fail "VERSION file missing" "Create a VERSION file with semantic version"
fi

if [ -f "$PROJECT_ROOT/README.md" ]; then
    pass "README.md exists"
else
    fail "README.md missing" "Add project documentation"
fi

echo ""

# ----------------------------------------
# 2. Reference Documents
# ----------------------------------------
echo "Reference Documents"
echo "-------------------"

REFS=(
    "libraries.md"
    "gotchas.md"
    "luau-conventions.md"
    "luau-patterns.md"
    "tool-versions.md"
    "asset-pipeline.md"
    "mcp-setup.md"
    "testing.md"
    "debugging.md"
    "quick-reference.md"
)

for ref in "${REFS[@]}"; do
    if [ -f "$PROJECT_ROOT/references/$ref" ]; then
        pass "references/$ref"
    else
        fail "references/$ref missing" "This doc is referenced in SKILL.md"
    fi
done

echo ""

# ----------------------------------------
# 3. Asset Files
# ----------------------------------------
echo "Asset Files"
echo "-----------"

# Config files
CONFIGS=(
    "config/default.project.json"
    "config/selene.toml"
    "config/stylua.toml"
    "config/.luaurc.json"
    "config/gitignore.txt"
    "config/gitattributes.txt"
    "config/wally.toml"
)

for config in "${CONFIGS[@]}"; do
    if [ -f "$PROJECT_ROOT/assets/$config" ]; then
        pass "assets/$config"
    else
        fail "assets/$config missing" "Required for project setup"
    fi
done

# Starter code
STARTER=(
    "starter-code/init.client.luau"
    "starter-code/init.server.luau"
    "starter-code/GameConfig.luau"
    "starter-code/Remotes.luau"
    "starter-code/Logger.luau"
    "starter-code/DataManager.luau"
    "starter-code/RateLimiter.luau"
    "starter-code/ErrorReporter.luau"
    "starter-code/Analytics.luau"
)

for starter in "${STARTER[@]}"; do
    if [ -f "$PROJECT_ROOT/assets/$starter" ]; then
        pass "assets/$starter"
    else
        fail "assets/$starter missing" "Starter code for new projects"
    fi
done

# VS Code settings
if [ -f "$PROJECT_ROOT/assets/vscode/settings.json" ]; then
    pass "assets/vscode/settings.json"
else
    fail "assets/vscode/settings.json missing" "VS Code settings template"
fi

if [ -f "$PROJECT_ROOT/assets/vscode/extensions.json" ]; then
    pass "assets/vscode/extensions.json"
else
    fail "assets/vscode/extensions.json missing" "Recommended extensions list"
fi

# CLAUDE.md template
if [ -f "$PROJECT_ROOT/assets/claude-template/CLAUDE.md" ]; then
    pass "assets/claude-template/CLAUDE.md"
else
    fail "assets/claude-template/CLAUDE.md missing" "Template for generated projects"
fi

echo ""

# ----------------------------------------
# 4. Install Scripts
# ----------------------------------------
echo "Install Scripts"
echo "---------------"

if [ -f "$PROJECT_ROOT/install.sh" ]; then
    pass "install.sh exists"

    # Check if ShellCheck is available
    if command -v shellcheck &> /dev/null; then
        if shellcheck "$PROJECT_ROOT/install.sh" &> /dev/null; then
            pass "install.sh passes ShellCheck"
        else
            fail "install.sh has ShellCheck warnings" "Run: shellcheck install.sh"
        fi
    else
        warn "ShellCheck not installed" "Install for script linting: brew install shellcheck"
    fi
else
    fail "install.sh missing" "macOS/Linux installer"
fi

if [ -f "$PROJECT_ROOT/install.ps1" ]; then
    pass "install.ps1 exists"
else
    fail "install.ps1 missing" "Windows installer"
fi

echo ""

# ----------------------------------------
# 5. Luau Code Quality
# ----------------------------------------
echo "Code Quality"
echo "------------"

# Check if Selene is available and configured
SELENE_OUTPUT=$(selene "$PROJECT_ROOT/assets/starter-code/" 2>&1)
SELENE_EXIT=$?

if echo "$SELENE_OUTPUT" | grep -q "rokit.toml\|selene.toml"; then
    # Selene can't run due to missing config in this directory
    warn "Selene not configured for this directory" "Add selene.toml or use Rokit in a project"
elif [ $SELENE_EXIT -eq 0 ]; then
    pass "Starter code passes Selene lint"
elif [ $SELENE_EXIT -eq 127 ]; then
    warn "Selene not installed" "Install via Rokit for Luau linting"
else
    fail "Starter code has Selene errors" "Run: selene assets/starter-code/"
fi

# Check if StyLua is available and configured
STYLUA_OUTPUT=$(stylua --check "$PROJECT_ROOT/assets/starter-code/" 2>&1)
STYLUA_EXIT=$?

if echo "$STYLUA_OUTPUT" | grep -q "rokit.toml"; then
    warn "StyLua not configured for this directory" "Add to Rokit or run from a project"
elif [ $STYLUA_EXIT -eq 0 ]; then
    pass "Starter code passes StyLua format check"
elif [ $STYLUA_EXIT -eq 127 ]; then
    warn "StyLua not installed" "Install via Rokit for Luau formatting"
else
    warn "Starter code needs formatting" "Run: stylua assets/starter-code/"
fi

echo ""

# ----------------------------------------
# 6. Skill Installation (if installed)
# ----------------------------------------
echo "Skill Installation"
echo "------------------"

SKILL_DIR="$HOME/.claude/skills/roblox-dev"

if [ -d "$SKILL_DIR" ]; then
    pass "Skill installed at ~/.claude/skills/roblox-dev/"

    if [ -f "$SKILL_DIR/SKILL.md" ]; then
        pass "Installed SKILL.md present"
    else
        fail "Installed SKILL.md missing" "Re-run the installer"
    fi

    if [ -d "$SKILL_DIR/references" ]; then
        pass "Installed references/ present"
    else
        fail "Installed references/ missing" "Re-run the installer"
    fi

    if [ -d "$SKILL_DIR/assets" ]; then
        pass "Installed assets/ present"
    else
        fail "Installed assets/ missing" "Re-run the installer"
    fi
else
    warn "Skill not installed" "Run the installer to test installation"
fi

echo ""

# ----------------------------------------
# Summary
# ----------------------------------------
echo "========================================"
echo "  Results"
echo "========================================"
echo ""
echo -e "  ${GREEN}Passed:${NC}  $PASS"
echo -e "  ${RED}Failed:${NC}  $FAIL"
echo -e "  ${YELLOW}Warnings:${NC} $WARN"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed. See details above.${NC}"
    exit 1
fi
