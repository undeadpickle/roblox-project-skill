<#
.SYNOPSIS
    Installs the Roblox Development Skill for Claude Code
.DESCRIPTION
    Downloads and installs the skill to ~/.claude/skills/roblox-dev/
.PARAMETER Version
    Specific version to install (e.g., "1.0.0"). If not specified, installs latest release.
#>

param(
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

$SkillName = "roblox-dev"
$RepoUrl = "https://github.com/undeadpickle/roblox-project-skill"
$SkillDir = "$env:USERPROFILE\.claude\skills\$SkillName"

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Roblox Development Skill Installer   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Fetch latest release version if not specified
if ([string]::IsNullOrEmpty($Version)) {
    Write-Host "→ Checking for latest release..." -ForegroundColor Yellow
    try {
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/undeadpickle/roblox-project-skill/releases/latest" -UseBasicParsing -ErrorAction SilentlyContinue
        $Version = $releaseInfo.tag_name -replace '^v', ''
        Write-Host "  Found version: v$Version" -ForegroundColor Gray
    }
    catch {
        Write-Host "  No releases found, using main branch" -ForegroundColor Gray
        $Version = "main"
    }
}

Write-Host "Installing to: $SkillDir"
Write-Host ""

# Create directory
if (-not (Test-Path $SkillDir)) {
    New-Item -ItemType Directory -Force -Path $SkillDir | Out-Null
}

# Download
Write-Host "→ Downloading..." -ForegroundColor Yellow
$TmpZip = "$env:TEMP\roblox-skill-$([guid]::NewGuid().ToString('N').Substring(0,8)).zip"
$TmpDir = "$env:TEMP\roblox-skill-extract"

try {
    if ($Version -eq "main") {
        $DownloadUrl = "$RepoUrl/archive/main.zip"
        $ExtractedDir = "$TmpDir\roblox-project-skill-main"
    }
    else {
        $DownloadUrl = "$RepoUrl/archive/refs/tags/v$Version.zip"
        $ExtractedDir = "$TmpDir\roblox-project-skill-$Version"
    }

    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TmpZip -UseBasicParsing

    Write-Host "→ Extracting..." -ForegroundColor Yellow
    if (Test-Path $TmpDir) { Remove-Item $TmpDir -Recurse -Force }
    Expand-Archive -Path $TmpZip -DestinationPath $TmpDir -Force

    Write-Host "→ Installing..." -ForegroundColor Yellow

    Copy-Item -Path "$ExtractedDir\SKILL.md" -Destination $SkillDir -Force
    Copy-Item -Path "$ExtractedDir\assets" -Destination $SkillDir -Recurse -Force
    Copy-Item -Path "$ExtractedDir\references" -Destination $SkillDir -Recurse -Force

    # Copy VERSION file if it exists
    if (Test-Path "$ExtractedDir\VERSION") {
        Copy-Item -Path "$ExtractedDir\VERSION" -Destination $SkillDir -Force
    }

    Write-Host ""
    Write-Host "✓ Installation complete!" -ForegroundColor Green
    if ($Version -ne "main") {
        Write-Host "  Version: v$Version" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  Ask Claude: `"Set up a new Roblox project`""
    Write-Host ""
    Write-Host "Docs: $RepoUrl#readme"
}
finally {
    # Cleanup
    if (Test-Path $TmpZip) { Remove-Item $TmpZip -Force }
    if (Test-Path $TmpDir) { Remove-Item $TmpDir -Recurse -Force }
}
