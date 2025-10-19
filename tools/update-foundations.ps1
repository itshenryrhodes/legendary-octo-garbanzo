Param(
  [string]$Section = 'foundations',
  [ValidateSet('newcomer','intermediate','advanced')]
  [string]$Path = 'newcomer'
)

$ErrorActionPreference = 'Stop'
$repo   = (& git rev-parse --show-toplevel).Trim()
if(-not $repo){ throw "Not in a Git repo" }
Set-Location $repo

$site   = Join-Path $repo 'site'
$root   = Join-Path $site 'wiki'
$sect   = Join-Path $root $Section
$target = Join-Path $sect 'index.html'

# Collect article files in this section
$files = Get-ChildItem $sect -File -Filter *.html -Recurse |
  Where-Object { $_.FullName -notlike '*index.html' }

# Extract fields from each candidate
$items = foreach($f in $files){
  $html = [IO.File]::ReadAllText($f.FullName, [Text.UTF8Encoding]::new($false))

  $sec  = [regex]::Match($html, '<meta\s+name="bpc:section"\s+content="([^"]+)"', 'IgnoreCase').Groups[1].Value
  $pth  = [regex]::Match($html, '<meta\s+name="bpc:path"\s+content="([^"]+)"',    'IgnoreCase').Groups[1].Value
  if($sec -ne $Section -or $pth -ne $Path){ continue }

  $title = [regex]::Match($html, '(?is)<title>(.*?)</title>').Groups[1].Value
  if($title -match '—'){ $title = ($title -split '—')[0].Trim() } # strip site suffix if present
  $desc  = [regex]::Match($html, '<meta\s+name="description"\s+content="([^"]+)"', 'IgnoreCase').Groups[1].Value
  $rel   = $f.FullName.Substring($site.Length).Replace('\','/')
  # Normalize to site-root path
  $href  = $rel

  [pscustomobject]@{
    Title = $title
    Desc  = $desc
    Href  = $href
    Sort  = $title
  }
}

if(-not $items){ Write-Warning "No $Section/$Path articles found."; exit 0 }

$items = $items | Sort-Object Sort

# Build <li> list
$li = $items | ForEach-Object {
  $t = [System.Web.HttpUtility]::HtmlEncode($_.Title)
  $d = [System.Web.HttpUtility]::HtmlEncode($_.Desc)
@"
<li><a href="$($_.Href)">$t</a> — <span class="muted">$d</span></li>
"@
} | Out-String

# Inject into target between markers
$begin = "<!-- BPC-AUTO:$Path:BEGIN -->"
$end   = "<!-- BPC-AUTO:$Path:END -->"
$doc   = [IO.File]::ReadAllText($target, [Text.UTF8Encoding]::new($false))

if($doc -notmatch [regex]::Escape($begin) -or $doc -notmatch [regex]::Escape($end)){
  throw "Markers $begin / $end not found in $target"
}

$pattern = "(?s)$([regex]::Escape($begin)).*?$([regex]::Escape($end))"
$replacement = "$begin`r`n<ul class=""list"">`r`n$li</ul>`r`n$end"
$updated = [regex]::Replace($doc, $pattern, $replacement)

if($updated -ne $doc){
  [IO.File]::WriteAllText($target, $updated, [Text.UTF8Encoding]::new($false))
  Write-Host "Updated $target ($($items.Count) $Path article(s))." -ForegroundColor Green
} else {
  Write-Host "No changes written (content identical)." -ForegroundColor Yellow
}
