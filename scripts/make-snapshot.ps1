<#
 make-snapshot.ps1
 - Runs the local build helpers (same as CI)
 - Copies /site to /snapshots/<stamp>/
 - Emits manifest.json (size + sha256 per file)
 - Zips the snapshot as site-snapshot-<stamp>-<shortsha>.zip
 - Optionally creates a lightweight tag and GitHub release (if gh is available)
#>

param(
  [switch]$Release,          # also create a GitHub release with asset
  [string]$Stamp             # override timestamp (default: now)
)

$ErrorActionPreference = "Stop"

function Ensure-Cmd($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "$name not found. Please install or add to PATH."
  }
}

# --- Guards / context
Ensure-Cmd git
Ensure-Cmd node

# At repo root?
if (-not (Test-Path ".git")) { throw "Run from the repo root (where .git exists)." }

# --- Derive metadata
$stamp = if ($Stamp) { $Stamp } else { Get-Date -Format "yyyyMMdd-HHmmss" }
$sha   = (git rev-parse --short=7 HEAD).Trim()
$tag   = "snapshot-$stamp-$sha"
$zip   = "site-snapshot-$stamp-$sha.zip"

# --- Run local build helpers (mirrors CI order)
Write-Host "→ Expanding includes…" -ForegroundColor Cyan
node scripts/expand-includes.js

Write-Host "→ Injecting SEO/OG meta…" -ForegroundColor Cyan
if (Test-Path scripts/inject-meta.js) { node scripts/inject-meta.js }

Write-Host "→ Building wiki search index…" -ForegroundColor Cyan
if (Test-Path scripts/build-search.js) { node scripts/build-search.js }

Write-Host "→ Building blog JSON + RSS…" -ForegroundColor Cyan
if (Test-Path scripts/build-blog.js) { node scripts/build-blog.js }

Write-Host "→ Injecting Google Tag Manager…" -ForegroundColor Cyan
if (Test-Path scripts/inject-gtm.js) { node scripts/inject-gtm.js }

# --- Stage snapshot directory
$root     = (Get-Location).Path
$src      = Join-Path $root "site"
$target   = Join-Path $root "snapshots\$stamp"
$manifest = Join-Path $target "manifest.json"

if (-not (Test-Path $src)) { throw "site/ folder not found." }
New-Item -ItemType Directory $target -Force | Out-Null

Write-Host "→ Copying site/ to snapshots/$stamp …" -ForegroundColor Cyan
# Use robocopy on Windows for speed/attrs
robocopy $src $target /E /NFL /NDL /NJH /NJS | Out-Null

# --- Build manifest (size + SHA256 per file)
Write-Host "→ Writing manifest with sizes and SHA256…" -ForegroundColor Cyan
$files = Get-ChildItem -File -Recurse $target
$entries = foreach ($f in $files) {
  $rel = $f.FullName.Substring($target.Length).TrimStart('\') -replace '\\','/'
  $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash.ToLower()
  [pscustomobject]@{
    path = "/$rel"
    size = $f.Length
    sha256 = $hash
  }
}
$meta = [pscustomobject]@{
  snapshot   = $stamp
  commit     = (git rev-parse HEAD).Trim()
  short_sha  = $sha
  generated  = (Get-Date).ToString("o")
  file_count = $entries.Count
  files      = $entries
}
$meta | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $manifest

# --- Zip it
Write-Host "→ Creating $zip …" -ForegroundColor Cyan
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $target "*") -DestinationPath $zip

# --- Write a small SNAPSHOT.md summary (helpful if attaching to release)
$snapNote = @"
# Bee Planet Connection — Snapshot

- Stamp: $stamp
- Commit: $sha
- Files: $($entries.Count)
- Zip: $zip

This snapshot was produced locally using:
- scripts/expand-includes.js
- scripts/inject-meta.js
- scripts/build-search.js
- scripts/build-blog.js
- scripts/inject-gtm.js
"@
$snapNotePath = "SNAPSHOT-$stamp-$sha.md"
$snapNote | Set-Content -Encoding UTF8 $snapNotePath

Write-Host ""
Write-Host "✅ Snapshot ready:" -ForegroundColor Green
Write-Host "  Folder : snapshots\$stamp"
Write-Host "  Manifest: snapshots\$stamp\manifest.json"
Write-Host "  Zip    : $zip"
Write-Host "  Notes  : $snapNotePath"

# --- Optional: tag + release
if ($Release) {
  if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "→ Creating lightweight tag $tag and GitHub release…" -ForegroundColor Cyan
    git tag -a $tag -m "Site snapshot $stamp ($sha)"
    git push origin $tag
    gh release create $tag --title "Snapshot $stamp" --notes-file $snapNotePath --prerelease
    gh release upload $tag $zip
    Write-Host "✅ Release published for $tag" -ForegroundColor Green
  } else {
    Write-Warning "gh not found; skipping GitHub release. Re-run with -Release after installing GitHub CLI."
  }
}
