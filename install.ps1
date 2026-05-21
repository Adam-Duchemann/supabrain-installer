# Supabrain one-line installer for Windows.
#
# Usage:
#   irm https://raw.githubusercontent.com/Adam-Duchemann/supabrain-installer/v1.0.0/install.ps1 | iex
#
# Requires (a one-time per developer setup):
#   1. A GitHub Personal Access Token (PAT) with `read:packages` scope.
#      Generate at: https://github.com/settings/tokens?type=beta
#   2. The script will write a per-user .npmrc with the @adam-duchemann scope mapping.

$ErrorActionPreference = "Stop"

# ----------------------------------------------------------------------------
# 1. Check Node 22+
# ----------------------------------------------------------------------------
$needsNode = $true
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
  $major = [int]((node -v).TrimStart('v').Split('.')[0])
  if ($major -ge 22) { $needsNode = $false }
}

if ($needsNode) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "X winget not found. Install Node 22+ from https://nodejs.org then re-run this script."
    exit 1
  }
  Write-Host "-> Installing Node 22 LTS via winget (a UAC prompt will appear)..."
  winget install -e --id OpenJS.NodeJS.LTS --silent

  # Refresh PATH from registry (machine + user).
  $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + `
              [System.Environment]::GetEnvironmentVariable("PATH", "User")

  # Even after refresh, the current session sometimes can't see npm.cmd.
  $nodeCheck = Get-Command node -ErrorAction SilentlyContinue
  $npmCheck = Get-Command npm -ErrorAction SilentlyContinue
  if (-not $nodeCheck -or -not $npmCheck) {
    Write-Host ""
    Write-Host "Node was installed but this PowerShell session can't see it yet."
    Write-Host "Open a NEW PowerShell window and re-run:"
    Write-Host "  irm https://raw.githubusercontent.com/Adam-Duchemann/supabrain-installer/v1.0.0/install.ps1 | iex"
    exit 0
  }
}

# ----------------------------------------------------------------------------
# 2. Check ~/.npmrc has the @adam-duchemann scope mapped to GitHub Packages
# ----------------------------------------------------------------------------
$npmrcPath = Join-Path $env:USERPROFILE ".npmrc"
$existing = ""
if (Test-Path $npmrcPath) {
  $existing = Get-Content $npmrcPath -Raw -ErrorAction SilentlyContinue
  if ($null -eq $existing) { $existing = "" }
}

if ($existing -notmatch "@adam-duchemann:registry=https://npm\.pkg\.github\.com") {
  Write-Host ""
  Write-Host "------------------------------------------------------------------"
  Write-Host "  One-time GitHub Packages auth setup"
  Write-Host "------------------------------------------------------------------"
  Write-Host ""
  Write-Host "  Supabrain is distributed via GitHub Packages (private). You need a"
  Write-Host "  GitHub Personal Access Token (PAT) with the 'read:packages' scope."
  Write-Host ""
  Write-Host "  1) Get your PAT from your workspace admin (sent via 1Password / Slack DM)."
  Write-Host "     Or generate your own: https://github.com/settings/tokens?type=beta"
  Write-Host ""
  Write-Host "  2) Paste it below (input hidden). It will be written to ~/.npmrc."
  Write-Host ""

  $secureToken = Read-Host -Prompt "  GitHub PAT (ghp_... or github_pat_...)" -AsSecureString
  $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
  $ghPat = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

  if ([string]::IsNullOrWhiteSpace($ghPat)) {
    Write-Host "X No token provided. Exiting."
    exit 1
  }

  $append = @"


# Supabrain (GitHub Packages, @adam-duchemann scope)
@adam-duchemann:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=$ghPat
"@

  Add-Content -Path $npmrcPath -Value $append -Encoding utf8

  Write-Host "OK Wrote @adam-duchemann scope auth to ~/.npmrc"
  Write-Host ""
}

# ----------------------------------------------------------------------------
# 3. Run the wizard. Pin to v1.0.0 so a broken latest doesn't break existing users.
# ----------------------------------------------------------------------------
Write-Host "-> Launching Supabrain setup wizard..."
npx --yes "@adam-duchemann/supabrain-setup@1.0.0" $args
