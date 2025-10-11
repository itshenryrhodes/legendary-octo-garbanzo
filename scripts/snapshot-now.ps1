param(
  [switch]$Release,          # also create a GitHub release with asset (if "gh" is available)
  [string]$Stamp             # override timestamp (default: now)
)

$ErrorActionPreference = "Stop"

function Ensure-Cmd($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "$name not found. Please install or add to PATH."
  }
}

function Invoke-NodeSafe($filePath) {
  if (-not (Test-Path $filePath)) { return }
  # Read JS, remove any *leading* /** ... */ JSDoc (fixes Node 22 header-parse quirks), run from a temp file.
  $js = Get-Content $filePath -Raw
  $fixed = [regex]::Replace($js, '^\s*/\*\*[\s\S]*?\*/\s*', '')
  $tmp = [System.IO.Path]::GetTempFileName() -replace '\.tmp$','.js'
  Set-Content -Encoding UTF8 $tmp $fixed
  try {
    node $tmp
  } catch {
    Write-Warning "Node helper failed: $filePath (`$($_.Exception.Message)`) — continuing."
  } finally {
    Remove-Item $tmp -ErrorAction SilentlyContinue
  }
}

# --- Guards / context
Ensure-Cmd git
Ensure-Cmd node
if (-not (Test-Path ".git")) { throw "Run from the repo root (where .git exists)." }

# --- Derive metadata
$stamp = if ($Stamp) { $Stamp } else { Get-Date -Format "yyyyMMdd-HHmmss" }
$sha   = (git rev-parse --short=7 HEAD).Trim()
$tag   = "snapshot-$stamp-$sha"
$zip   = "site-snapshot-$stamp-$sha.zip"

# --- Build helpers (safe for Node 22)
Write-Host "→ Expanding includes…" -ForegroundColor Cyan
Invoke-NodeSafe "scripts/expand-includes.js"

Write-Host "→ Injecting SEO/OG meta…" -ForegroundColor Cyan
Invoke-NodeSafe "scripts/inject-meta.js"

Write-Host "→ Building wiki search index…" -ForegroundColor Cyan
Invoke-NodeSafe "scripts/build-search.js"

Write-Host "→ Building blog JSON + RSS…" -ForegroundColor Cyan
Invoke-NodeSafe "scripts/build-blog.js"

Write-Host "→ Injecting Google Tag Manager…" -ForegroundColor Cyan
Invoke-NodeSafe "scripts/inject-gtm.js"

# --- Stage snapshot directory
$root     = (Get-Location).Path
$src      = Join-Path $root "site"
if (-not (Test-Path $src)) { throw "site/ folder not found." }

$target   = Join-Path $root "snapshots\$stamp"
$manifest = Join-Path $target "manifest.json"
New-Item -ItemType Directory $target -Force | Out-Null

Write-Host "→ Copying site/ to snapshots/$stamp …" -ForegroundColor Cyan
robocopy $src $target /E /NFL /NDL /NJH /NJS | Out-Null

# --- Build manifest (size + SHA256 per file)
Write-Host "→ Writing manifest with sizes and SHA256…" -ForegroundColor Cyan
$files = Get-ChildItem -File -Recurse $target
$entries = foreach ($f in $files) {
  $rel = $f.FullName.Substring($target.Length).TrimStart('\') -replace '\\','/'
  $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash.ToLower()
  [pscustomobject]@{
    path   = "/$rel"
    size   = $f.Length
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

# --- Tag current commit
Write-Host "→ Creating tag $tag …" -ForegroundColor Cyan
git tag -a $tag -m "Site snapshot $stamp ($sha)"
git push origin $tag

# --- Write a small SNAPSHOT.md summary (handy to keep around)
$snapNote = @"
# Bee Planet Connection — Snapshot

- Stamp: $stamp
- Commit: $sha
- Files: $($entries.Count)
- Zip: $zip

Produced using the local helpers:
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
Write-Host "  Tag    : $tag"
Write-Host "  Notes  : $snapNotePath"

# --- Optional: publish a GitHub prerelease with the ZIP
if ($Release) {
  if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "→ Creating GitHub release for $tag …" -ForegroundColor Cyan
    gh release create $tag --title "Snapshot $stamp" --notes-file $snapNotePath --prerelease
    gh release upload $tag $zip
    Write-Host "✅ Release published for $tag" -ForegroundColor Green
  } else {
    Write-Warning "gh not found; skipping GitHub release. Re-run with -Release after installing GitHub CLI."
  }
}
