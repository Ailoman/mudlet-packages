# setup-github.ps1
# Run this ONCE from the mudlet-packages-repo folder to create the GitHub
# repo and push everything up.
#
# Prerequisites:
#   - git  (https://git-scm.com/download/win)
#   - gh   (https://cli.github.com/) — run `gh auth login` first if not done
#
# Usage:
#   cd C:\Users\ailoj\.config\mudlet\profiles\IceTest\mudlet-packages-repo
#   .\setup-github.ps1

param(
    [string]$RepoName    = "mudlet-packages",
    [string]$Description = "Custom Mudlet packages for Icesus MUD",
    [string]$Visibility  = "public"   # or "private"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "==> Initialising git repo..." -ForegroundColor Cyan
git init
git add .
git commit -m "Initial commit: add all packages"

Write-Host "==> Creating GitHub repo '$RepoName'..." -ForegroundColor Cyan
gh repo create $RepoName `
    --description $Description `
    --$Visibility `
    --source . `
    --remote origin `
    --push

Write-Host ""
Write-Host "All done! Your repo is live at:" -ForegroundColor Green
gh repo view --json url -q ".url"
