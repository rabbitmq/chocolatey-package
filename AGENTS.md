# AGENTS.md - AI Assistant Context

This file provides comprehensive context for AI assistants working on this repository.

## Repository Purpose

This repository manages the Chocolatey package for RabbitMQ using the Chocolatey-AU (Automatic Updater) framework. AU automates detection of new RabbitMQ releases and updates the package accordingly.

**Maintainer:** Team RabbitMQ
**Repository:** https://github.com/rabbitmq/chocolatey-package
**Chocolatey Package:** https://community.chocolatey.org/packages/rabbitmq

## Architecture Overview

### Package Management Strategy

**Single package type:** RabbitMQ - downloads installer at install time (not embedded in nupkg)

**Key principle:** Nuspec and install scripts are committed with current versions, not templates. AU updates them in place when new versions are released.

### Directory Structure

```
chocolatey-package/
├── .github/workflows/
│   ├── update.yml              # Daily package updates (5:30 AM UTC)
│   └── validate.yml            # PSScriptAnalyzer on push/PR
├── _modules/au/                # AU module submodule (fork with PS7 fixes)
├── rabbitmq/                   # RabbitMQ package
│   ├── rabbitmq.nuspec         # Package metadata (committed with current version)
│   ├── update.ps1              # AU update script
│   ├── rabbitmq-logo.png       # Package icon
│   └── tools/
│       ├── chocolateyInstall.ps1    # Install script
│       ├── chocolateyUninstall.ps1  # Uninstall script
│       └── ChocolateyHelpers.ps1    # Helper functions
├── Shared.ps1                  # Common utility functions
├── Update-Packages.ps1         # AU batch updater
├── Invoke-Validation.ps1       # PSScriptAnalyzer validation
├── PSScriptAnalyzerSettings.psd1
└── README.md
```

### Gitignored Files

- `*.nupkg` - Generated packages
- `*.exe` - Downloaded installers
- `Update-AUPackages.md` - Generated reports
- `Update-History.md` - Generated history
- `update_vars.ps1` - Local configuration (secrets)
- `update_info.xml` - AU run information

**Important:** Nuspec files and install scripts are NOT gitignored - they're committed with current versions.

## The RabbitMQ Package

**What:** RabbitMQ multi-protocol messaging and streaming broker
**Source:** https://github.com/rabbitmq/rabbitmq-server
**Package Type:** Downloads installer at install time (not embedded)

**Key features:**
- Downloads Windows installer from GitHub releases
- Gets checksums from GitHub release `digest` field
- Supports package parameters for customization
- Enables management plugin by default

**Package parameters:**
- `/NOMANAGEMENT` - Don't enable RabbitMQ management plugin
- `/RABBITMQBASE` - Set custom RABBITMQ_BASE directory

**Dependencies:**
- `erlang` package version `[26.0,28.0)` - RabbitMQ requires Erlang/OTP

## Shared.ps1 Functions

### Get-RepositoryRoot

Finds the repository root by walking up the directory tree looking for `.git` directory.

**Used by:** `Import-AUModule` to locate the AU submodule

### Import-AUModule

Imports Chocolatey-AU module from submodule or global install. Checks for global module first, falls back to `_modules/au` submodule.

**Used by:** All package update scripts

## Key Scripts

### Update-Packages.ps1

AU batch updater that processes all packages. Calls `Update-AUPackages` with configured options.

**Key configuration:**
- `Push = $Env:au_Push -eq 'true'` - Enable pushing
- `Threads = 10` - Parallel package processing
- Git plugin enabled with `Branch = 'main'`
- Gist plugin for update reports
- Report and History plugins for markdown output

**Environment variables required:**
- `au_Push` - 'true' or 'false' (string, not boolean!)
- `api_key` - Chocolatey API key
- `github_api_key` - GitHub token (repo + gist scopes)
- `github_user_repo` - Format: 'rabbitmq/chocolatey-package'
- `gist_id` - Gist ID for update reports (optional)

### Invoke-Validation.ps1

Runs PSScriptAnalyzer on all PowerShell files with configured rules.

**Checks:**
- Code quality (aliases, Write-Host, etc.)
- Formatting (indentation, braces, whitespace)
- PowerShell 7 compatibility
- Excludes `_modules/` directory

**Usage:**
```powershell
.\Invoke-Validation.ps1
```

### rabbitmq/update.ps1

AU update script for the RabbitMQ package.

**Key functions:**

#### au_GetLatest

Fetches latest release from GitHub using `gh.exe`:
```powershell
$releaseJson = & gh.exe release view --repo rabbitmq/rabbitmq-server --json 'tagName,url,assets'
```

Returns hashtable with:
- `Version` - Release version (e.g., "4.2.3")
- `URL64` - Download URL for Windows installer
- `Checksum64` - SHA256 checksum from GitHub digest field
- `ReleaseNotes` - URL to GitHub release page

#### au_SearchReplace

Defines regex replacements for updating files:
- `tools\chocolateyInstall.ps1` - Updates `$url` and `$checksum` variables
- `rabbitmq.nuspec` - Updates `<releaseNotes>` element

**Important:** The install script uses `$url` variable (full URL) instead of `$version` because AU adds a date suffix to versions for Chocolatey fix notation, which would break URL construction.

## AU Framework

### How AU Works

1. Reads nuspec to get current version
2. Calls `au_GetLatest` to get remote version
3. Compares versions
4. If remote > current AND version doesn't exist on Chocolatey:
   - Updates files via `au_SearchReplace`
   - Packs the package
   - Pushes if `$Options.Push = $true`

### AU Plugins (configured in Update-Packages.ps1)

- **Report** - Generates markdown update report
- **History** - Tracks update history
- **Gist** - Publishes reports to GitHub gist
- **Git** - Commits updated files back to repository
- **RunInfo** - Saves run information

### Version Handling

AU adds a date suffix for "fix notation" when the version hasn't changed but files have:
- Original: `4.2.3`
- With fix: `4.2.3.20260126`

This is why the install script uses `$url` (full URL) instead of constructing URL from `$version`.

## GitHub Actions Workflows

### update.yml

**Trigger:** Daily at 5:30 AM UTC, or manual (`workflow_dispatch`)
**Permissions:** `contents: write` (for Git plugin to commit)

**Steps:**
1. Checkout with submodules
2. Configure git user
3. Run `Update-Packages.ps1`

**What happens on update:**
- AU detects new RabbitMQ version
- Updates nuspec and install scripts
- Packs package
- Pushes to Chocolatey
- Git plugin commits updated files back to repository

**Required secrets:**
- `CHOCOLATEY_API_KEY` - API key for chocolatey.org
- `API_KEY` - GitHub token with `repo` and `gist` scopes

**Environment variables:**
- `au_Push: 'true'` - Enable pushing
- `GH_TOKEN` - For gh.exe (automatic from `github.token`)
- `github_api_key` - From `API_KEY` secret
- `github_user_repo` - 'rabbitmq/chocolatey-package'
- `api_key` - From `CHOCOLATEY_API_KEY` secret

### validate.yml

**Trigger:** Push or PR to main branch
**Permissions:** `contents: read`

**Steps:**
1. Checkout
2. Install PSScriptAnalyzer
3. Run `Invoke-Validation.ps1`

## Common Patterns

### Using gh.exe for GitHub API

The package uses `gh.exe` instead of `Invoke-WebRequest`:

```powershell
$releaseJson = & gh.exe release view --repo rabbitmq/rabbitmq-server --json 'tagName,url,assets'
if ($LASTEXITCODE -ne 0) {
    throw "Failed to get release from GitHub"
}
$release = $releaseJson | ConvertFrom-Json
```

**Benefits:**
- Automatic authentication via `GH_TOKEN`
- Structured JSON output
- Handles rate limiting

### Checksum from GitHub Digest

GitHub provides SHA256 checksums in release asset `digest` field:

```powershell
$exeAsset = $release.assets | Where-Object { $_.name -match '^rabbitmq-server-[0-9.]+\.exe$' }
if ($exeAsset.digest) {
    $checksum = ($exeAsset.digest -split ':')[1]  # Format: "sha256:hash"
}
```

**Benefit:** No need to download the installer to calculate checksum.

## Testing

### Local Package Testing

```powershell
cd rabbitmq

# Test update detection
.\update.ps1

# Force update (even if no new version)
$au_Force = $true
.\update.ps1

# Verify package contents
7z l *.nupkg

# Test installation
choco install rabbitmq -dv -source "."

# Test uninstallation
choco uninstall rabbitmq -y
```

### Test Full AU Workflow

```powershell
cd D:\development\rabbitmq\chocolatey-package
$Env:au_Push = 'false'
.\Update-Packages.ps1
```

### Validation

```powershell
# Run PSScriptAnalyzer on all files
.\Invoke-Validation.ps1
```

### Testing Checklist

Before committing changes:

1. `.\Invoke-Validation.ps1` passes
2. Package updates successfully (`$au_Force = $true; .\update.ps1`)
3. Package installs locally
4. RabbitMQ works correctly
5. Package uninstalls cleanly
6. Test in fresh PowerShell session

## Troubleshooting

### "Cannot index into a null array"

**Cause:** Stale AU functions from previous run in same PowerShell session.

**Solution:** Start fresh PowerShell session or run cleanup:
```powershell
Remove-Item Function:\au_* -ErrorAction Ignore
Remove-Variable -Name au_* -Scope Global -ErrorAction Ignore
```

### "Version already exists" (409 error)

**Cause:** Trying to push version that's already on Chocolatey.

**Solution:** Check if nuspec version matches what's on Chocolatey. Git plugin should have committed the updated version.

### "File not found" during choco push

**Cause:** PowerShell 7 empty string bug (if using old AU module).

**Solution:** Use the AU submodule fork which has the fix.

### Workflow Fails to Commit

**Cause:** Git plugin not configured or token lacks permissions.

**Check:**
- `API_KEY` secret has `repo` scope
- `github_user_repo` environment variable is set correctly
- `Branch = 'main'` in Git plugin config

### Line Ending Issues

**Cause:** AU may write files with CRLF line endings.

**Solution:** Run `dos2unix` on affected files before committing, or configure `.gitattributes` to enforce LF.

## Important Notes

### Line Endings

- All files use LF (Unix-style)
- `.gitattributes` enforces this
- AU submodule may write CRLF - use `dos2unix` if needed

### PowerShell Session State

AU functions persist across script runs in same session. Always test in fresh session or clean up:

```powershell
Remove-Item Function:\au_* -ErrorAction Ignore
Remove-Variable -Name au_* -Scope Global -ErrorAction Ignore
Remove-Item Env:\au_* -ErrorAction Ignore
```

### Version Strings

**Always strings, never booleans:**
- `au_Push: 'true'` not `au_Push: true`
- AU checks with string comparison: `$Env:au_Push -eq 'true'`

### Git Plugin Behavior

**Only commits when packages are pushed:**
- Commits only modified files in package directories
- Includes `[skip ci]` in commit message to prevent workflow loops

**Requires:**
- `github_api_key` with `repo` scope
- `github_user_repo` environment variable
- `Branch` parameter matching your branch name

### Erlang Dependency

RabbitMQ requires Erlang/OTP. The package declares dependency:
```xml
<dependency id="erlang" version="[26.0,28.0)" />
```

This means Erlang 26.x or 27.x is required. Update this range when RabbitMQ adds support for newer Erlang versions.

## AU Module Submodule

### Location and Source

**Location:** `_modules/au`
**Source:** https://github.com/chocolatey-beam/cc-chocolatey-au
**Branch:** `fix/powershell-7-compatibility`

### Fixes in Our Fork

1. **PowerShell 7 empty string bug** - Fixed in `Push-Package.ps1`
2. **SSH URL support** - Fixed in `Git.ps1` plugin
3. **PowerShell 7 compatibility** - Fixed in `RunInfo.ps1` plugin

### Updating Submodule

```powershell
cd _modules/au
git pull origin fix/powershell-7-compatibility
cd ../..
git add _modules/au
git commit -m "Update AU submodule"
```

## Command Reference

### Package Updates

```powershell
# Single package update
cd rabbitmq
$au_Force = $true
.\update.ps1

# All packages (no push)
$Env:au_Push = 'false'
.\Update-Packages.ps1
```

### Validation

```powershell
.\Invoke-Validation.ps1
```

## Links and References

### This Repository

- **Repository:** https://github.com/rabbitmq/chocolatey-package
- **Chocolatey Package:** https://community.chocolatey.org/packages/rabbitmq

### RabbitMQ

- **Website:** https://www.rabbitmq.com/
- **GitHub:** https://github.com/rabbitmq/rabbitmq-server
- **Documentation:** https://www.rabbitmq.com/docs

### Chocolatey-AU

- **Upstream:** https://github.com/chocolatey-community/chocolatey-au
- **Our Fork:** https://github.com/chocolatey-beam/cc-chocolatey-au
- **AU Wiki:** https://github.com/chocolatey-community/chocolatey-au/wiki

### Chocolatey

- **Package Guidelines:** https://docs.chocolatey.org/en-us/create/create-packages
- **Moderation:** https://docs.chocolatey.org/en-us/community-repository/moderation/

### Related Packages

- **Erlang:** https://community.chocolatey.org/packages/erlang (dependency)
- **BEAM AU Packages:** https://github.com/chocolatey-beam/au-packages

---

**Last Updated:** January 26, 2026
**Maintainer:** Team RabbitMQ
