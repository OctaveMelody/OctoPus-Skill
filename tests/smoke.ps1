[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = (Get-Item (Join-Path $PSScriptRoot '..')).FullName
$skill = Join-Path $repo '.agents\skills\octopus-jps-transcription-review'
$scripts = Join-Path $skill 'scripts'
$tempRoot = Join-Path $repo 'output\smoke-tests'
$null = New-Item -ItemType Directory -Path $tempRoot -Force
$tempRoot = (Get-Item -LiteralPath $tempRoot).FullName
$scratch = Join-Path $tempRoot ('octopus-skill-smoke-' + [guid]::NewGuid().ToString('N'))
function Assert([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }

foreach ($file in (Get-ChildItem -LiteralPath $scripts -Filter '*.ps1' -File)) {
    $tokens = $null; $errors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    Assert ($errors.Count -eq 0) "PowerShell syntax error in $($file.Name): $errors"
}

try {
    $null = New-Item -ItemType Directory -Path $scratch
    $work = Join-Path $scratch 'work'
    $null = New-Item -ItemType Directory -Path $work
    $image = Join-Path $scratch 'example.png'
    [IO.File]::WriteAllBytes($image, [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/aXcAAAAASUVORK5CYII='))
    $hash = (Get-FileHash -LiteralPath $image -Algorithm SHA256).Hash
    Push-Location $work
    try {
        $one = & (Join-Path $scripts 'new-review-workspace.ps1') -InputPath $image
        Assert (Test-Path -LiteralPath $one.OutputDirectory -PathType Container) 'Workspace was not created.'
        Assert ($one.SourceSha256 -eq $hash) 'Source hash does not match.'
        Assert ($one.OutputDirectory -eq (Join-Path $work 'output\example')) 'Default output is not under the working directory.'
        $two = & (Join-Path $scripts 'new-review-workspace.ps1') -InputPath $image
        Assert ($two.OutputDirectory -ne $one.OutputDirectory) 'Default output collision was not avoided.'
        $blocked = $false
        try { & (Join-Path $scripts 'new-review-workspace.ps1') -InputPath $image -OutputDirectory $one.OutputDirectory | Out-Null } catch { $blocked = $true }
        Assert $blocked 'Existing workspace was not rejected.'

        $code = "V: 1.0`nB: Test`nD: C`nP: 4/4`nQ: 1 2 3 4 ||`n"
        $wrapped = Join-Path $scratch 'wrapped.jps'
        $json = @{ code = $code; page_config = @{ paper = 'A4' } } | ConvertTo-Json -Depth 4
        [IO.File]::WriteAllText($wrapped, $json, (New-Object Text.UTF8Encoding($false)))
        $plain = Join-Path $work 'plain.jps'
        $null = & (Join-Path $scripts 'export-plain-jps.ps1') -InputPath $wrapped -OutputPath $plain
        Assert ([IO.File]::ReadAllText($plain) -ceq $code) 'Wrapped JPS code was not preserved.'
        $copy = Join-Path $work 'copy.jps'
        $null = & (Join-Path $scripts 'export-plain-jps.ps1') -InputPath $plain -OutputPath $copy
        Assert ([IO.File]::ReadAllText($copy) -ceq $code) 'Plain JPS text was not preserved.'
        $blocked = $false
        try { & (Join-Path $scripts 'export-plain-jps.ps1') -InputPath $plain -OutputPath $copy | Out-Null } catch { $blocked = $true }
        Assert $blocked 'Existing JPS output was not rejected.'
        Assert ((Get-FileHash -LiteralPath $image -Algorithm SHA256).Hash -eq $hash) 'Source was modified.'
    } finally { Pop-Location }

    $install = Join-Path $scratch 'installed\octopus-jps-transcription-review'
    & (Join-Path $scripts 'install-user-skill.ps1') -Destination $install | Out-Null
    Assert (Test-Path -LiteralPath (Join-Path $install 'SKILL.md') -PathType Leaf) 'Installed skill is missing SKILL.md.'
    Assert (Test-Path -LiteralPath (Join-Path $install 'scripts\new-review-workspace.ps1') -PathType Leaf) 'Installed skill is missing its helper.'
    $blocked = $false
    try { & (Join-Path $scripts 'install-user-skill.ps1') -Destination $install | Out-Null } catch { $blocked = $true }
    Assert $blocked 'Existing installation was not rejected.'
    Write-Output 'Skill smoke checks passed.'
} finally {
    if (Test-Path -LiteralPath $scratch) {
        $resolved = (Resolve-Path -LiteralPath $scratch).Path
        $prefix = [IO.Path]::GetFullPath($tempRoot).TrimEnd([char[]]@('\','/')) + [IO.Path]::DirectorySeparatorChar
        if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Split-Path -Leaf $resolved).StartsWith('octopus-skill-smoke-')) {
            throw "Refusing to remove unexpected test directory: $resolved"
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
