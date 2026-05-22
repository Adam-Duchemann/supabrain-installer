#!/usr/bin/env bash
# Supabrain one-line installer for macOS and Linux.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Adam-Duchemann/supabrain-installer/v1.2.0/install.sh | bash
#
# Requires (a one-time per developer setup):
#   1. A GitHub Personal Access Token (PAT) with `read:packages` scope.
#      Generate at: https://github.com/settings/tokens?type=beta
#      Resource access: scope to "Adam-Duchemann/supabrain" only.
#   2. ~/.npmrc configured (this script will write it if missing):
#        @adam-duchemann:registry=https://npm.pkg.github.com
#        //npm.pkg.github.com/:_authToken=ghp_xxx
#
# If you don't have the PAT yet, the script prints instructions and exits.

set -euo pipefail

# ----------------------------------------------------------------------------
# 1. Check Node 22+
# ----------------------------------------------------------------------------
NODE_OK=false
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR=$(node -v | sed 's/v//' | cut -d. -f1)
  [[ "$NODE_MAJOR" -ge 22 ]] && NODE_OK=true
fi

if ! $NODE_OK; then
  if command -v brew >/dev/null 2>&1; then
    echo "→ Installing Node 22 via Homebrew..."
    brew install node@22
    BREW_NODE_PREFIX="$(brew --prefix node@22)"
    export PATH="$BREW_NODE_PREFIX/bin:$PATH"
  else
    echo "✗ Node 22+ required."
    echo "  Install from https://nodejs.org or via Homebrew (brew install node@22), then re-run."
    exit 1
  fi
fi

# ----------------------------------------------------------------------------
# 2. Check ~/.npmrc has the @adam-duchemann scope mapped to GitHub Packages
# ----------------------------------------------------------------------------
NPMRC="$HOME/.npmrc"
if ! grep -q "@adam-duchemann:registry=https://npm.pkg.github.com" "$NPMRC" 2>/dev/null; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  One-time GitHub Packages auth setup"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Supabrain is distributed via GitHub Packages (private). You need a"
  echo "  GitHub Personal Access Token (PAT) with the 'read:packages' scope."
  echo ""
  echo "  1) Get your PAT from your workspace admin (sent via 1Password / Slack DM)."
  echo "     Or generate your own: https://github.com/settings/tokens?type=beta"
  echo ""
  echo "  2) Paste it below (input hidden). It will be written to ~/.npmrc."
  echo ""
  read -srp "  GitHub PAT (ghp_... or github_pat_...): " GH_PAT
  echo ""
  if [[ -z "$GH_PAT" ]]; then
    echo "✗ No token provided. Exiting."
    exit 1
  fi

  # Append (don't overwrite — preserve existing .npmrc entries).
  {
    echo ""
    echo "# Supabrain (GitHub Packages, @adam-duchemann scope)"
    echo "@adam-duchemann:registry=https://npm.pkg.github.com"
    echo "//npm.pkg.github.com/:_authToken=${GH_PAT}"
  } >> "$NPMRC"

  echo "✓ Wrote @adam-duchemann scope auth to ~/.npmrc"
  echo ""
fi

# ----------------------------------------------------------------------------
# 3. Run the wizard. Pin to a specific version so a broken latest doesn't
# break existing users. v1.2.0 bundles docs (USAGE.md, /save-to-supabrain
# slash command, memory-save skill) AND publishes @adam-duchemann/supabrain-ui
# so teammates can launch the browser dashboard with `npx … supabrain-ui start`.
# See Adam-Duchemann/supabrain v1.2.0.
# ----------------------------------------------------------------------------
echo "→ Launching Supabrain setup wizard..."
exec npx --yes @adam-duchemann/supabrain-setup@1.2.0 "$@"
