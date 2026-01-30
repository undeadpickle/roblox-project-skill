#!/bin/bash
set -e

SKILL_NAME="roblox-dev"
REPO_URL="https://github.com/undeadpickle/roblox-project-skill"

# Detect install location
if [ -d "/mnt/skills/user" ]; then
    # claude.ai computer use environment
    SKILL_DIR="/mnt/skills/user/${SKILL_NAME}"
else
    # Claude Code local environment
    SKILL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
fi

echo "╔════════════════════════════════════════╗"
echo "║   Roblox Development Skill Installer   ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Installing to: $SKILL_DIR"
echo ""

# Create directory
mkdir -p "$SKILL_DIR"

# Download and extract
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

echo "→ Downloading..."
if command -v curl &> /dev/null; then
    curl -sL "${REPO_URL}/archive/main.tar.gz" -o "$TMP_DIR/repo.tar.gz"
elif command -v wget &> /dev/null; then
    wget -q "${REPO_URL}/archive/main.tar.gz" -O "$TMP_DIR/repo.tar.gz"
else
    echo "Error: curl or wget required"
    exit 1
fi

echo "→ Extracting..."
tar -xzf "$TMP_DIR/repo.tar.gz" -C "$TMP_DIR"

echo "→ Installing..."
cp "$TMP_DIR/roblox-project-skill-main/SKILL.md" "$SKILL_DIR/"
cp -r "$TMP_DIR/roblox-project-skill-main/assets" "$SKILL_DIR/"
cp -r "$TMP_DIR/roblox-project-skill-main/references" "$SKILL_DIR/"

echo ""
echo "✓ Installation complete!"
echo ""
echo "Usage:"
echo "  Ask Claude: \"Set up a new Roblox project\""
echo ""
echo "Docs: ${REPO_URL}#readme"
