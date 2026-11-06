[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$InputPath,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$sourceItem = Get-Item -LiteralPath $InputPath -ErrorAction Stop
if ($sourceItem.PSProvider.Name -ne 'FileSystem' -or $sourceItem.PSIsContainer) {
    throw 'InputPath must name a local file.'
}
$source = $sourceItem.FullName
if ([IO.Path]::GetExtension($source).ToLowerInvariant() -notin @('.png', '.jpg', '.jpeg', '.pdf')) {
    throw 'Input must be a PNG, JPG, JPEG or PDF file.'
}
$location = Get-Location
if ($location.Provider.Name -ne 'FileSystem') { throw 'Run the helper from a filesystem directory.' }
$stem = [IO.Path]::GetFileNameWithoutExtension($source)
foreach ($invalid in [IO.Path]::GetInvalidFileNameChars()) { $stem = $stem.Replace([string]$invalid, '_') }
$stem = $stem.TrimEnd([char[]]@(' ', '.'))
if ([string]::IsNullOrWhiteSpace($stem)) { $stem = 'score' }
if ($stem -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') { $stem = "score-$stem" }

if ($OutputDirectory) {
    if ([IO.Path]::IsPathRooted($OutputDirectory)) { $target = [IO.Path]::GetFullPath($OutputDirectory) }
    else { $target = [IO.Path]::GetFullPath((Join-Path $location.ProviderPath $OutputDirectory)) }
    if (Test-Path -LiteralPath $target) { throw "Output directory already exists: '$target'" }
} else {
    $base = Join-Path (Join-Path $location.ProviderPath 'output') $stem
    $target = $base
    if (Test-Path -LiteralPath $target) { $target = "$base-$(Get-Date -Format 'yyyyMMdd-HHmmssfff')" }
    if (Test-Path -LiteralPath $target) { throw "Output collision: '$target'. Choose -OutputDirectory." }
}
$hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$null = New-Item -ItemType Directory -Path $target -ErrorAction Stop
[pscustomobject]@{ SourcePath = $source; SourceSha256 = $hash; OutputDirectory = $target }
