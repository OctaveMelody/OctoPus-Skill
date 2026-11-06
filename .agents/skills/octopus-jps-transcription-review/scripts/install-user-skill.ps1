[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Destination = (Join-Path $env:USERPROFILE '.agents\skills\octopus-jps-transcription-review')
)

$ErrorActionPreference = 'Stop'
$source = (Get-Item (Join-Path $PSScriptRoot '..')).FullName
$target = [System.IO.Path]::GetFullPath($Destination)
$sourcePrefix = $source.TrimEnd([char[]]@('\', '/')) + [System.IO.Path]::DirectorySeparatorChar
if ($target.Equals($source, [System.StringComparison]::OrdinalIgnoreCase) -or
    $target.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Destination cannot be the skill source folder or a child of it.'
}
if (Test-Path -LiteralPath $target) {
    throw "Destination already exists; refusing to replace it: '$target'"
}
if ($PSCmdlet.ShouldProcess($target, 'Copy OctoPus transcription review skill')) {
    $parent = Split-Path -Parent $target
    $null = New-Item -ItemType Directory -Force -Path $parent
    $null = New-Item -ItemType Directory -Path $target
    Get-ChildItem -LiteralPath $source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse
    }
    Write-Output "Installed skill to: $target"
    Write-Output 'Launch the installed or portable OctoPus application when using this skill.'
}
