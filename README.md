# Supabrain Installer

One-line bootstrap scripts for installing [Supabrain](https://github.com/Adam-Duchemann/supabrain) on Mac, Linux, and Windows.

The scripts are tiny wrappers around `npx @adam-duchemann/supabrain-setup`. They handle: detecting/installing Node 22+, prompting for a GitHub PAT once (to install the private GitHub Packages tarball), then launching the interactive wizard.

> **This is a public repo by design.** It contains shell scripts only — no secrets, no proprietary code. Anyone can fetch and read them; they only do something useful if you have a GitHub PAT with `read:packages` scope for the (private) `Adam-Duchemann/supabrain` repo.

## Install

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/Adam-Duchemann/supabrain-installer/v1.0.0/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/Adam-Duchemann/supabrain-installer/v1.0.0/install.ps1 | iex
```

## What you need before running

1. **A GitHub Personal Access Token** with `read:packages` scope.
   - Your workspace admin will send this to you via 1Password or Slack DM.
   - If you're an admin generating PATs for your team: https://github.com/settings/tokens?type=beta — restrict resource access to `Adam-Duchemann/supabrain` only.

2. **Optionally, Node.js 22+.** The script auto-installs via Homebrew (Mac/Linux) or winget (Windows) if missing.

## What the installer does

```
┌─ Detects Node 22+. Auto-installs if missing.
├─ Writes ~/.npmrc with @adam-duchemann scope → GitHub Packages registry.
├─ Prompts for your GitHub PAT once and stores it (gitignored .npmrc).
└─ Runs `npx @adam-duchemann/supabrain-setup@1.0.0` — the interactive wizard:
    ├─ Project list + prefixes
    ├─ Embedding provider (Gemini or OpenAI)
    ├─ Local SQLite DB path
    ├─ Cloud sync (optional):
    │   ├─ Supabase URL + anon (public) key
    │   ├─ Your email + password (Supabase Auth)
    │   └─ Device name
    └─ MCP server path (auto-detected from node_modules)
```

After it finishes, restart Claude Code. Verify with `claude mcp list` — you should see `supabrain-io` connected.

## Troubleshooting

**`curl: (22) The requested URL returned error: 404`**
The version tag in the URL is wrong. Check the [Releases](https://github.com/Adam-Duchemann/supabrain-installer/releases) page for the latest tag.

**`irm | iex` blocked by execution policy on Windows**
The `irm | iex` pattern executes in-memory and usually bypasses RemoteSigned policy. If yours is stricter:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```
Then re-run.

**Native module compilation errors (`better-sqlite3` / `sqlite-vec`)**
Native deps ship prebuilts for Mac (x64 + arm64), Windows x64, and Linux x64. Windows-on-ARM is not supported in v1; `sqlite-vec` will fall back to a JS path (semantic search slower but functional).

**`npm ERR! 403 Forbidden` or `404 Not Found` when installing**
Your PAT doesn't have `read:packages` scope, OR your PAT's resource access doesn't include `Adam-Duchemann/supabrain`. Generate a new one with the right scope.

**`Node was installed but this PowerShell session can't see it yet`**
Windows-specific: winget installed Node but the PATH hasn't refreshed in your current session. Open a new PowerShell window and re-run the `irm | iex` command.

## Sources

- The installer scripts: this repo. Read them before piping — they're <60 lines each.
- The wizard package: `@adam-duchemann/supabrain-setup` on GitHub Packages.
- The MCP server: `@adam-duchemann/supabrain-server` on GitHub Packages.
- Project source: https://github.com/Adam-Duchemann/supabrain (private).

## Versioning

Install scripts are pinned to a release tag in the one-liner URLs (e.g. `…/v1.0.0/install.sh`). Future releases get new tags; the URL doesn't change unless you opt in. This means a broken release of `@adam-duchemann/supabrain-setup` doesn't retroactively break devs who installed earlier — they keep using the version their installer pinned.
