param(
  [string[]]$Include = @("site/**/*.html","site/**/*.htm","site/**/*.css","site/**/*.js","site/**/*.json","site/**/*.md","site/**/*.yml","site/**/*.xml","site/**/*.csv","site/**/*.txt","site/**/*.svg"),
  [switch]$SummaryOnly
)

$ErrorActionPreference = "Stop"
$utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
$cp1252     = [Text.Encoding]::GetEncoding(1252)

function MojibakeFromUtf8Hex([byte[]]$bytes) {
  # Intentionally wrong decode: interpret raw UTF-8 bytes as CP1252 to produce the mojibake token
  return $cp1252.GetString($bytes)
}
function DoubleEncode([string]$s) {
  # Take CP1252 mojibake -> encode as UTF-8 bytes -> decode again as CP1252 for the double-encoded form
  $utf8 = [Text.Encoding]::UTF8
  return $cp1252.GetString($utf8.GetBytes($s))
}

# Build tokens safely (em/en dash, curly quotes, ellipsis, NBSP marker)
$tokens = @()
$tokens += MojibakeFromUtf8Hex(0xE2,0x80,0x94) # em dash -> "Ã¢â‚¬â€"
$tokens += MojibakeFromUtf8Hex(0xE2,0x80,0x93) # en dash -> "Ã¢â‚¬â€œ"
$tokens += MojibakeFromUtf8Hex(0xE2,0x80,0x99) # rsquo   -> "Ã¢â‚¬â„¢"
$tokens += MojibakeFromUtf8Hex(0xE2,0x80,0x98) # lsquo   -> "Ã¢â‚¬Ëœ"
$tokens += MojibakeFromUtf8Hex(0xE2,0x80,0x9C) # ldquo   -> "Ã¢â‚¬Å“"
$tokens += MojibakeFromUtf8Hex(0xE2,0x80,0x9D) # rdquo   -> "Ã¢â‚¬ï¿½"
$tokens += MojibakeFromUtf8Hex(0xE2,0x80,0xA6) # ellipsis-> "Ã¢â‚¬Â¦"
$tokens += "Ã‚"                                     # stray NBSP marker when mangled

# Add their double-encoded counterparts (e.g., "ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬ï¿½")
$tokens = $tokens + ($tokens | ForEach-Object { DoubleEncode $_ })

# Scan files
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
  try { $text = $utf8Strict.GetString($bytes) } catch {
    $violations += "{0}: Invalid UTF-8 bytes" -f $f.FullName
    continue
  }

  # U+FFFD replacement char
  if ($text.Contains([string][char]0xFFFD)) {
    $violations += "{0}: Contains U+FFFD replacement char" -f $f.FullName
    continue
  }

  # Token scan
  foreach($tok in $tokens){
    if ($null -ne $tok -and $tok -ne '' -and $text -like ("*{0}*" -f $tok)) {
      $violations += "{0}: Contains mojibake token (auto-generated)" -f $f.FullName
      break
    }
  }
}

if ($violations.Count -gt 0) {
  if (-not $SummaryOnly) {
    Write-Host "âœ– Encoding/mojibake violations:" -ForegroundColor Red
    $violations | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
  } else {
    $violations | ForEach-Object { Write-Output $_ }
  }
  exit 1
}

Write-Host "No encoding/mojibake issues found."

