<#
.SYNOPSIS
    Installs the Roblox Development Skill for Claude Code
.DESCRIPTION
    Downloads and installs the skill to ~/.claude/skills/roblox-dev/
#>

$ErrorActionPreference = "Stop"

$SkillName = "roblox-dev"
$RepoUrl = "https://github.com/undeadpickle/roblox-project-skill"
$SkillDir = "$env:USERPROFILE\.claude\skills\$SkillName"

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Roblox Development Skill Installer   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
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
    Invoke-WebRequest -Uri "$RepoUrl/archive/main.zip" -OutFile $TmpZip -UseBasicParsing
    
    Write-Host "→ Extracting..." -ForegroundColor Yellow
    if (Test-Path $TmpDir) { Remove-Item $TmpDir -Recurse -Force }
    Expand-Archive -Path $TmpZip -DestinationPath $TmpDir -Force
    
    Write-Host "→ Installing..." -ForegroundColor Yellow
    $ExtractedDir = "$TmpDir\roblox-project-skill-main"
    
    Copy-Item -Path "$ExtractedDir\SKILL.md" -Destination $SkillDir -Force
    Copy-Item -Path "$ExtractedDir\assets" -Destination $SkillDir -Recurse -Force
    Copy-Item -Path "$ExtractedDir\references" -Destination $SkillDir -Recurse -Force
    
    Write-Host ""
    Write-Host "✓ Installation complete!" -ForegroundColor Green
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
