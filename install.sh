#!/bin/bash
set -e

SKILL_NAME="roblox-dev"
REPO_URL="https://github.com/undeadpickle/roblox-project-skill"

# Parse arguments
VERSION=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --version|-v)
            VERSION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: install.sh [--version <version>]"
            exit 1
            ;;
    esac
done

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

# Fetch latest release version if not specified
if [ -z "$VERSION" ]; then
    echo "→ Checking for latest release..."
    VERSION=$(curl -s "https://api.github.com/repos/undeadpickle/roblox-project-skill/releases/latest" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/' || echo "")

    if [ -z "$VERSION" ]; then
        echo "  No releases found, using main branch"
        VERSION="main"
    else
        echo "  Found version: v$VERSION"
    fi
fi

echo "Installing to: $SKILL_DIR"
echo ""

# Create directory
mkdir -p "$SKILL_DIR"

# Download and extract
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

echo "→ Downloading..."
if [ "$VERSION" = "main" ]; then
    DOWNLOAD_URL="${REPO_URL}/archive/main.tar.gz"
    EXTRACT_DIR="roblox-project-skill-main"
else
    DOWNLOAD_URL="${REPO_URL}/archive/refs/tags/v${VERSION}.tar.gz"
    EXTRACT_DIR="roblox-project-skill-${VERSION}"
fi

if command -v curl &> /dev/null; then
    curl -sL "$DOWNLOAD_URL" -o "$TMP_DIR/repo.tar.gz"
elif command -v wget &> /dev/null; then
    wget -q "$DOWNLOAD_URL" -O "$TMP_DIR/repo.tar.gz"
else
    echo "Error: curl or wget required"
    exit 1
fi

echo "→ Extracting..."
tar -xzf "$TMP_DIR/repo.tar.gz" -C "$TMP_DIR"

echo "→ Installing..."
cp "$TMP_DIR/$EXTRACT_DIR/SKILL.md" "$SKILL_DIR/"
cp -r "$TMP_DIR/$EXTRACT_DIR/assets" "$SKILL_DIR/"
cp -r "$TMP_DIR/$EXTRACT_DIR/references" "$SKILL_DIR/"

# Copy VERSION file if it exists
if [ -f "$TMP_DIR/$EXTRACT_DIR/VERSION" ]; then
    cp "$TMP_DIR/$EXTRACT_DIR/VERSION" "$SKILL_DIR/"
fi

echo ""
echo "✓ Installation complete!"
if [ "$VERSION" != "main" ]; then
    echo "  Version: v$VERSION"
fi
echo ""
echo "Usage:"
echo "  Ask Claude: \"Set up a new Roblox project\""
echo ""
echo "Docs: ${REPO_URL}#readme"
