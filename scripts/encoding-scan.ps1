param(
  [string[]]$Include = @("site/**/*.html","site/**/*.htm","site/**/*.css","site/**/*.js","site/**/*.json","site/**/*.md","site/**/*.yml","site/**/*.xml","site/**/*.csv","site/**/*.txt","site/**/*.svg"),
  [switch]$SummaryOnly
)

$ErrorActionPreference = "Stop"
$utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)

$badTokens = @(
  "Ã¢â‚¬â€�","Ã¢â‚¬â€œ","Ã¢â‚¬â„¢","Ã¢â‚¬Ëœ","Ã¢â‚¬Å“","Ã¢â‚¬Â","Ã¢â‚¬Â¦","Ã‚",
  "â€™","â€˜","â€œ","â€�","â€“","â€”","â€¦","Â",
  "ï¿½","€”","€” # include the Euro+dash cases we saw
)

$paths = @()
foreach($glob in $Include){
  $glob = $glob -replace '/','\'
  $paths += Get-ChildItem -Path $glob -File -ErrorAction SilentlyContinue
}

$violations = @()

foreach($f in $paths){
  $bytes = [IO.File]::ReadAllBytes($f.FullName)

  # BOM check
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $violations += "{0}: BOM present" -f $f.FullName
    continue
  }

  # Strict decode check
  try {
    $text = $utf8Strict.GetString($bytes)
  } catch {
    $violations += "{0}: Invalid UTF-8 bytes" -f $f.FullName
    continue
  }

  # U+FFFD replacement char
  if ($text.Contains([string][char]0xFFFD)) {
    $violations += "{0}: Contains U+FFFD replacement char" -f $f.FullName
    continue
  }

  # Token scan
  foreach($tok in $badTokens){
    if ($text -like ("*{0}*" -f $tok)) {
      $violations += "{0}: Contains mojibake token '{1}'" -f $f.FullName, $tok
      break
    }
  }
}

if ($violations.Count -gt 0) {
  if (-not $SummaryOnly) {
    Write-Host "✖ Encoding/mojibake violations:" -ForegroundColor Red
    $violations | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
  } else {
    $violations | ForEach-Object { Write-Output $_ }
  }
  exit 1
}

Write-Host "✓ No encoding/mojibake issues found."