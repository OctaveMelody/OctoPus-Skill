# Windows workflow

The public CLI is the default for current OctoPus packages. It uses the same local engine and exporters as the desktop application, returns structured JSON, and does not use an embedded LLM. The vision-capable host agent still performs the complete source-to-render review.

## Discover the CLI

Resolve the selected installation or complete portable package to its full path. In current packages, `octopus-cli.exe` is beside `octopus.exe` at the package/install root. Invoke the CLI by its fully resolved path; do not rely on `PATH` or the current directory:

```powershell
$appRoot = 'C:\Program Files\OctoPus' # or the selected portable package root
$cli = (Resolve-Path -LiteralPath (Join-Path $appRoot 'octopus-cli.exe')).Path
function Invoke-OctoPusCli {
    param([Parameter(Mandatory = $true)][string]$Executable,
          [Parameter(Mandatory = $true)][string[]]$Arguments)
    $previousEncoding = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
        $stdout = @(& $Executable @Arguments)
        $exitCode = $LASTEXITCODE
    } finally {
        [Console]::OutputEncoding = $previousEncoding
    }
    [pscustomobject]@{ ExitCode = $exitCode; Stdout = ($stdout -join [Environment]::NewLine) }
}

$probe = Invoke-OctoPusCli -Executable $cli -Arguments @('capabilities', '--json')
$raw = $probe.Stdout
$exitCode = $probe.ExitCode
if ($exitCode -ne 0) { throw "OctoPus capability query failed with exit code $exitCode." }
$capabilities = $raw | ConvertFrom-Json -ErrorAction Stop
if ($capabilities.status -ne 'ok') { throw "OctoPus capabilities returned status '$($capabilities.status)' with code '$($capabilities.error.code)'." }
```

PowerShell waits for the console process to finish. `Invoke-OctoPusCli` captures stdout as UTF-8 and restores the previous console encoding; stderr remains separate for progress messages. Use it for every CLI call and do not merge stderr into the JSON text. This skill supports capability schema major version `1`; check that `schema_version` is compatible and `commands` includes the requested operations. Record `product_version`. For image/PDF transcription, confirm `transcription_available`; for PDF, also confirm `pdf_transcription.available` and `transcription_formats` includes `pdf`; for PNG comparison pages, confirm `png_export_available` and `export_formats` includes `png`.

If the selected package does not contain `octopus-cli.exe`, follow the older-package desktop workflow below. Do not probe the GUI `octopus.exe` with `--headless`: older GUI builds can ignore the argument and open a window or hang. Once the CLI has returned a recognized capability object, use it for this task. If a CLI operation later fails, repair the stated issue or stop; do not switch to the UI as a fallback.

## Prepare the workspace and transcribe

From a writable working directory, create a new output folder and record the source SHA-256:

```powershell
$workspace = & '<skill-path>\scripts\new-review-workspace.ps1' -InputPath 'C:\Scores\example.pdf'
$workspace | Format-List
$source = $workspace.SourcePath
$out = $workspace.OutputDirectory
$draft = Join-Path $out 'example-draft.jps'
$issues = Join-Path $out 'example-issues.json'
```

Use a unique output folder and new draft/issue paths. The CLI refuses to overwrite outputs. Run the selected image or PDF through the transcriber and keep the final JSON result:

```powershell
$call = Invoke-OctoPusCli -Executable $cli -Arguments @('transcribe', $source, '--out', $draft, '--issues', $issues, '--json')
$exitCode = $call.ExitCode
if ($exitCode -ne 0) { throw "OctoPus transcription failed with exit code ${exitCode}: $($call.Stdout)" }
$result = $call.Stdout | ConvertFrom-Json -ErrorAction Stop
if ($result.status -ne 'ok') { throw "OctoPus transcription returned status '$($result.status)'." }
```

Record `draft_path`, `issues_path`, `page_count`, `issue_count`, and structured `issues`; the paths in the JSON are absolute. The separate issue file has `status: review_required`. For a PDF, require `transcription_available` and `pdf_transcription.available` before starting, then make sure the returned processed source-page count matches the full document. If `pdf_transcription.missing` lists tools, report that capability gap before transcription; do not start and then change interfaces after an error.

## Inspect and export rendered pages

`inspect` and `export` accept either plain JPS text or a JSON-wrapped OctoPus document containing `code` and page settings. `inspect` returns `document_name`, `json_wrapped`, `encoding_repaired`, `source_offset_unit`, `parse_diagnostics`, `score_diagnostics`, rendered `page_count`, and `custom_markup_omitted`. Use its diagnostics to catch parser errors, but do not use a clean parse as evidence of musical accuracy.

```powershell
$inspectCall = Invoke-OctoPusCli -Executable $cli -Arguments @('inspect', $draft, '--json')
$inspectRaw = $inspectCall.Stdout
$exitCode = $inspectCall.ExitCode
if ($exitCode -ne 0) { throw "OctoPus inspect failed with exit code $exitCode." }
$draftInfo = $inspectRaw | ConvertFrom-Json -ErrorAction Stop
if ($draftInfo.status -ne 'ok') { throw "OctoPus inspect returned status '$($draftInfo.status)'." }

$draftPages = Join-Path $out 'draft-pages'
$null = New-Item -ItemType Directory -Path $draftPages
$exportCall = Invoke-OctoPusCli -Executable $cli -Arguments @('export', $draft, '--format', 'png', '--out-dir', $draftPages, '--dpi', '300', '--json')
$exportRaw = $exportCall.Stdout
$exitCode = $exportCall.ExitCode
if ($exitCode -ne 0) { throw "OctoPus draft export failed with exit code $exitCode." }
$draftExport = $exportRaw | ConvertFrom-Json -ErrorAction Stop
if ($draftExport.status -ne 'ok') { throw "OctoPus draft export returned status '$($draftExport.status)'." }
```

Use the returned `outputs` paths and `page_count`; paths in `outputs` are absolute. For PNG with multiple pages, files use the JPS filename stem with suffixes such as `_page_001.png`; a single page uses the unsuffixed stem. Confirm the export count and all returned files. Review every source PDF page in order against the corresponding score content; a page count alone does not prove that every system was transcribed.

After editing a separate reviewed JPS, run `inspect` and export it to a new `reviewed-pages` directory in the same way. Compare every source system with the final rendered pages from the beginning. If `custom_markup_omitted` is true, record that fact and inspect the output for any lost custom notation.

For a plain UTF-8 JPS deliverable from a wrapped document, extract its `code` field to a different new file:

```powershell
& '<skill-path>\scripts\export-plain-jps.ps1' -InputPath '<wrapped-reviewed.jps>' -OutputPath '<reviewed-plain.jps>'
```

The helper also copies plain JPS and refuses to overwrite its input or an existing destination. Keep the raw engine draft, issue JSON, reviewed OctoPus document (if wrapped), plain reviewed JPS, page exports and review report distinct. Recheck the source hash at the end:

```powershell
Get-FileHash -LiteralPath $source -Algorithm SHA256
```

## Handle conflicts and CLI errors

Check both the process exit code and JSON `status`. Exit codes are `0` success, `1` execution failure, `2` usage/invalid input, `3` missing capability, and `4` active-session conflict. The CLI does not overwrite existing output files.

- On `status: conflict` / exit `4` (`active_session_conflict`), read `error.conflict.path` and `error.conflict.sessions`, including each session's `windowLabel`, `documentName`, `dirty`, `conflictLatched`, and `processId`. If the conflicting document is open with unsaved edits, do not close it. Ask the user to save and close the named OctoPus session, or cancel. Once closed, verify the output paths are still unused and retry the same command once. Do not fall back to desktop transcription because of a conflict.
- If an output target already exists, choose a different new output name or directory and retry without deleting or replacing that file.
- For any other nonzero exit or `status: error`, report the returned code and message, fix the issue if possible, or stop. Do not retry through the desktop workflow.

## Older-package desktop workflow

Use this only when the selected package does not contain the public CLI. Launch the installed app or run `octopus.exe` from the complete portable folder. Choose **Import → JPG / PNG / PDF**, select the designated source, then choose **Transcribe → Transcribe New**. Save a distinct draft in the new workspace before editing. Record the app version and visible findings.

Compare Original Image/PDF and SVG preview side by side at readable zoom, system by system. Export PNG pages using **Export → PNG**, inspect every source page and final rendered page, and record any limitation where issue JSON is unavailable. Preserve the draft, source, hash, outputs and report. This desktop path is for packages without a detected CLI; it is not a recovery path after a CLI operation fails.
