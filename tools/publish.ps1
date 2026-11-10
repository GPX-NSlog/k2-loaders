param(
  [ValidateSet('new', 'release')]
  [string]$Mode = 'release',
  [string]$ApiKey = $env:FACTORIO_API_KEY,
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$Category = 'content',
  [string]$License = 'GNU LGPLv3',
  [string]$SourceUrl = 'https://github.com/GPX-NSlog/k2-loaders',
  [string]$Proxy = $env:HTTPS_PROXY
)

# Usage:
#   First publish (creates the mod on the portal):  .\tools\publish.ps1 -Mode new
#   Later releases:                                 .\tools\publish.ps1 -Mode release
# Get an API key from https://factorio.com/profile (Mod Portal upload key).
# You can also put $ApiKey = '...' into tools/config.local.ps1 (gitignored).
# If the machine needs an HTTP proxy, set $env:HTTPS_PROXY or pass -Proxy.

$ErrorActionPreference = 'Stop'

$configFile = Join-Path $PSScriptRoot 'config.local.ps1'
if (Test-Path $configFile) {
  . $configFile
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
  throw 'Set FACTORIO_API_KEY or pass -ApiKey.'
}

$zip = & (Join-Path $PSScriptRoot 'package.ps1') -ProjectRoot $ProjectRoot
$zip = $zip.Replace('\', '/')
$info = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $ProjectRoot 'info.json') | ConvertFrom-Json

if ($Mode -eq 'new') {
  $initUrl = 'https://mods.factorio.com/api/v2/mods/init_publish'
} else {
  $initUrl = 'https://mods.factorio.com/api/v2/mods/releases/init_upload'
}

$headers = @{
  Authorization = "Bearer $ApiKey"
}

$initParams = @{
  Method  = 'Post'
  Uri     = $initUrl
  Headers = $headers
  Body    = @{ mod = $info.name }
}
if (-not [string]::IsNullOrWhiteSpace($Proxy)) {
  $initParams['Proxy'] = $Proxy
}

$init = Invoke-RestMethod @initParams
$uploadUrl = $init.upload_url
if (-not $uploadUrl) {
  throw "Factorio API did not return upload_url. Response: $($init | ConvertTo-Json -Depth 10)"
}

Add-Type -AssemblyName System.Net.Http

$zipFile = Get-Item -LiteralPath $zip.Replace('/', '\')
$fileContent = [System.IO.File]::ReadAllBytes($zipFile.FullName)
$fileContentStream = New-Object System.IO.MemoryStream(,$fileContent)

$content = New-Object System.Net.Http.MultipartFormDataContent
$content.Add((New-Object System.Net.Http.StreamContent($fileContentStream)), 'file', $zipFile.Name)

if ($Mode -eq 'new') {
  $content.Add((New-Object System.Net.Http.StringContent($Category)), 'category')
  $content.Add((New-Object System.Net.Http.StringContent($License)), 'license')
  $content.Add((New-Object System.Net.Http.StringContent($SourceUrl)), 'source_url')
}

$handler = New-Object System.Net.Http.HttpClientHandler
if (-not [string]::IsNullOrWhiteSpace($Proxy)) {
  $handler.Proxy = New-Object System.Net.WebProxy($Proxy)
  $handler.UseProxy = $true
}
$httpClient = New-Object System.Net.Http.HttpClient($handler)
$httpResponse = $httpClient.PostAsync($uploadUrl, $content).Result

if ($httpResponse.IsSuccessStatusCode) {
  Write-Host "Upload OK: $($httpResponse.Content.ReadAsStringAsync().Result)"
} else {
  throw "Upload failed (HTTP $([int]$httpResponse.StatusCode)): $($httpResponse.Content.ReadAsStringAsync().Result)"
}
