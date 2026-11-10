param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$DistDir = (Join-Path $ProjectRoot 'dist')
)

$ErrorActionPreference = 'Stop'

$info = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $ProjectRoot 'info.json') | ConvertFrom-Json
$packageName = "$($info.name)_$($info.version)"
$stage = Join-Path $DistDir $packageName
$zip = Join-Path $DistDir "$packageName.zip"

# The first version in changelog.txt must match info.json, otherwise the portal rejects the upload.
$changelog = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $ProjectRoot 'changelog.txt')
if ($changelog -notmatch 'Version:\s*([0-9.]+)') {
  throw 'No "Version:" line found in changelog.txt.'
}
if ($Matches[1] -ne $info.version) {
  throw "changelog.txt version $($Matches[1]) does not match info.json version $($info.version)."
}

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

$resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$resolvedDist = (Resolve-Path -LiteralPath $DistDir).Path
if (-not $resolvedDist.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw 'Dist path is outside project root.'
}

foreach ($path in @($stage, $zip)) {
  if (Test-Path -LiteralPath $path) {
    $resolved = (Resolve-Path -LiteralPath $path).Path
    if (-not $resolved.StartsWith($resolvedDist, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Path is outside dist: $path"
    }
    Remove-Item -LiteralPath $path -Recurse -Force
  }
}

New-Item -ItemType Directory -Force -Path $stage | Out-Null

# Only ship files the running mod needs; build tooling and test data stay out of the zip.
$items = @(
  'info.json',
  'control.lua',
  'settings.lua',
  'data.lua',
  'data-final-fixes.lua',
  'changelog.txt',
  'CREDITS.md',
  'LICENSE',
  'locale',
  'prototypes',
  'scripts',
  'graphics',
  'thumbnail.png'
)

foreach ($item in $items) {
  $source = Join-Path $ProjectRoot $item
  if (Test-Path -LiteralPath $source) {
    Copy-Item -LiteralPath $source -Destination $stage -Recurse
  }
}

$sevenZip = Get-Command 7z -ErrorAction SilentlyContinue
if ($sevenZip) {
  Set-Location $DistDir
  & $sevenZip.Source a "$zip" $packageName -r -mx9 -y *>$null
  Set-Location $ProjectRoot
} else {
  # Fall back to bsd tar shipped with Windows, which also writes forward-slash entry paths.
  & tar -a -c -f "$zip" -C "$DistDir" "$packageName"
}

Write-Output $zip
