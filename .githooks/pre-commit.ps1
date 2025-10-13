param()

$ErrorActionPreference = "Stop"

# Git provides staged files via diff --cached
$staged = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -ne "" }

if (-not $staged) { exit 0 }

# Patterns that commonly show up as mojibake (both single- and double-encoded variants)
$badStrings = @(
  "Ã¢â‚¬â€�","Ã¢â‚¬â€œ","Ã¢â‚¬â„¢","Ã¢â‚¬Ëœ","Ã¢â‚¬Å“","Ã¢â‚¬Â","Ã¢â‚¬Â¦","Ã‚",
  "â€™","â€˜","â€œ","â€�","â€“","â€”","â€¦","Â",
  "ï¿½",   # U+FFFD shown as literal in many tools
  "€”"    # observed fake dash combo
)

# File globs we treat as text (aligns with .gitattributes)
$textGlobs = @("*.html","*.htm","*.css","*.js","*.json","*.md","*.yml","*.xml","*.csv","*.txt","*.svg")

function Test-IsTextFile([string]$path, [string[]]$globs){
  foreach($g in $globs){ if ([bool][System.Management.Automation.WildcardPattern]::new($g).IsMatch($path)){ return $true } }
  return $false
}

# Strict UTF-8 decoder that throws on invalid bytes
$utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)

$failures = @()

foreach ($f in $staged) {
  if (-not (Test-IsTextFile $f $textGlobs)) { continue }

  if (-not (Test-Path $f)) { continue }

  $bytes = [System.IO.File]::ReadAllBytes($f)

  # 1) Fail if BOM present (we want UTF-8 without BOM)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $failures += "BOM present: $f"
    continue
  }

  # 2) Fail if not valid UTF-8 (decoder throws)
  try {
    $text = $utf8Strict.GetString($bytes)
  } catch {
    $failures += "Invalid UTF-8 bytes: $f"
    continue
  }

  # 3) Fail if U+FFFD replacement char appears
  if ($text.Contains([string][char]0xFFFD)) {
    $failures += "Contains U+FFFD replacement char: $f"
    continue
  }

  # 4) Fail if any known mojibake sequences appear
  foreach ($bad in $badStrings) {
    if ($text -like ("*" + $bad + "*")) {
      $failures += "Contains mojibake token '$bad' in $f"
      break
    }
  }
}

if ($failures.Count -gt 0) {
  Write-Host "✖ Pre-commit check failed:" -ForegroundColor Red
  $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
  Write-Host "`nFix the above issues and re-stage before committing." -ForegroundColor Yellow
  exit 1
}

exit 0
