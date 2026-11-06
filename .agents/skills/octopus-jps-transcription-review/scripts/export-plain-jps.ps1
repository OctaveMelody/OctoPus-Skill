[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$InputPath,
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$inputItem = Get-Item -LiteralPath $InputPath -ErrorAction Stop
if ($inputItem.PSProvider.Name -ne 'FileSystem' -or $inputItem.PSIsContainer) { throw 'InputPath must name a local file.' }
$location = Get-Location
if ($location.Provider.Name -ne 'FileSystem') { throw 'Run the helper from a filesystem directory.' }
if ([IO.Path]::IsPathRooted($OutputPath)) { $target = [IO.Path]::GetFullPath($OutputPath) }
else { $target = [IO.Path]::GetFullPath((Join-Path $location.ProviderPath $OutputPath)) }
if ([IO.Path]::GetExtension($target).ToLowerInvariant() -ne '.jps') { throw 'OutputPath must end in .jps.' }
if (Test-Path -LiteralPath $target) { throw "Output already exists; refusing to overwrite: '$target'" }
$text = [IO.File]::ReadAllText($inputItem.FullName, [Text.Encoding]::UTF8)
if ($text.TrimStart().StartsWith('{')) {
    try { $document = ConvertFrom-Json -InputObject $text -ErrorAction Stop }
    catch { throw 'Input begins with a JSON object but is not valid JSON.' }
    if ($document.code -isnot [string]) { throw 'The OctoPus JSON document must contain a string code field.' }
    $text = $document.code
}
$stream = [IO.File]::Open($target, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
try {
    $writer = New-Object IO.StreamWriter($stream, (New-Object Text.UTF8Encoding($false)))
    try { $writer.Write($text) } finally { $writer.Dispose() }
} finally { $stream.Dispose() }
[pscustomobject]@{ InputPath = $inputItem.FullName; OutputPath = $target; Sha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash }
