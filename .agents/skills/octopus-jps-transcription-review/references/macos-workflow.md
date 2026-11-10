# macOS workflow (Apple Silicon)

The public CLI is the default for current OctoPus packages. It uses the local transcription/parser/render engine and does not contain or invoke an LLM. The active vision-capable host agent must still compare every source page and rendered page and correct the JPS.

## Package and prerequisites

macOS releases are Apple Silicon disk images named `OctoPus_<version>_arm64_macos.dmg` for macOS 26 or later. There is no macOS portable folder and no separate console launcher: the headless interface is the app bundle's own executable with `--headless`.

1. Mount the DMG and copy **OctoPus.app** to `/Applications` (or another stable local folder). Do not run the CLI from the mounted read-only DMG.
2. The build is not signed with an Apple Developer ID or notarized, so Gatekeeper can block it as "damaged". Clear the quarantine attribute once, as documented by OctoPus, for a copy taken from the official releases page:

   ```sh
   sudo xattr -cr /Applications/OctoPus.app
   ```

   If a headless run is still killed or refused because of quarantine, clear the attribute and report the result; do not disable Gatekeeper globally or alter the bundle.

3. PDF transcription needs Poppler's `pdfinfo`, `pdftotext` and `pdftoppm` on `PATH`, which the package does not include. Install them and confirm the same shell that runs the CLI can see them:

   ```sh
   brew install poppler
   export PATH="/opt/homebrew/bin:$PATH"   # Apple Silicon Homebrew, if not already on PATH
   command -v pdfinfo pdftotext pdftoppm
   ```

## Detect the public CLI

Resolve the installed bundle, read its executable name from `Info.plist` rather than assuming it, and run the non-mutating capability query. `--headless` must come before the CLI command:

```sh
app='/Applications/OctoPus.app'
cli="$app/Contents/MacOS/$(plutil -extract CFBundleExecutable raw "$app/Contents/Info.plist")"
"$cli" --headless capabilities --json
```

The successful JSON object has `status: "ok"`; it is written to stdout, while progress and worker messages go to stderr. Check its exit code and that `schema_version` is compatible with major version `1` and that `commands` lists the needed operations. Record `product_version`. For image/PDF transcription, confirm `transcription_available`; for PDF, also confirm `pdf_transcription.available` and that `transcription_formats` includes `pdf`; for comparison images, confirm `png_export_available` and that `export_formats` includes `png`.

A capability query that launches and returns valid JSON is the acceptance check for the CLI on this platform. If the package predates the CLI or explicitly reports that headless commands are unsupported, continue with the older-package desktop workflow. A launch failure, `worker_unavailable`, or a missing packaged worker is an installation problem to report and fix, not proof of an older release, and never a reason to switch to the desktop workflow after a CLI operation has started and failed.

## Prepare the workspace and transcribe

The POSIX helper is shared by the Linux and macOS workflows (`python3` 3.11 or newer; on a fresh macOS host install it with `brew install python@3.12` or your usual toolchain). Create a new workspace and record the source hash:

```sh
python3 '<skill-path>/scripts/linux-review.py' prepare '/absolute/path/score.pdf'
```

Use the helper's returned `OutputDirectory` and `SourceSha256` fields. Select new paths for the draft and issue JSON, then run the CLI synchronously. Keep stdout separate from stderr and check both the exit code and JSON `status`:

```sh
out='/absolute/path/to/output/score'
source='/absolute/path/to/score.pdf'
draft="$out/score-draft.jps"
issues="$out/score-issues.json"

result=$("$cli" --headless transcribe "$source" --out "$draft" --issues "$issues" --json)
code=$?
if [ "$code" -ne 0 ]; then printf '%s\n' "$result" >&2; exit "$code"; fi
printf '%s\n' "$result"
```

The successful JSON result has `status: "ok"` and includes absolute `draft_path` and `issues_path`, `page_count`, `issue_count`, and structured `issues`. The separate issue file has `status: review_required`. `page_count` counts source pages successfully recognized. For a PDF, only start after `transcription_available` and `pdf_transcription.available` are true; if `pdf_transcription.missing` lists required tools, report that capability gap before starting. Confirm the returned source page count against the complete PDF and read every PDF page in order during visual review.

## Inspect and export rendered pages

`inspect` and `export` accept plain JPS or a JSON-wrapped OctoPus document with `code` and page settings. `inspect` returns `document_name`, `json_wrapped`, `encoding_repaired`, `source_offset_unit`, `parse_diagnostics`, `score_diagnostics`, rendered `page_count`, and `custom_markup_omitted`.

```sh
inspect=$("$cli" --headless inspect "$draft" --json)
code=$?
if [ "$code" -ne 0 ]; then printf '%s\n' "$inspect" >&2; exit "$code"; fi
printf '%s\n' "$inspect"

draft_pages="$out/draft-pages"
mkdir "$draft_pages"
export=$("$cli" --headless export "$draft" --format png --out-dir "$draft_pages" --dpi 300 --json)
code=$?
if [ "$code" -ne 0 ]; then printf '%s\n' "$export" >&2; exit "$code"; fi
printf '%s\n' "$export"
```

Check `status` for these commands too, then use the absolute `outputs` paths and `page_count` and inspect every file. For PNG with multiple pages, files use the JPS filename stem with suffixes such as `_page_001.png`; a single page uses the unsuffixed stem. Keep output directories and target files new; existing targets are never overwritten. After editing a separate reviewed JPS, run `inspect` and export the reviewed pages to a new directory. If `custom_markup_omitted` is true, record it and check for lost custom notation.

Judge musical accuracy from the notation, not from typeface shapes: the macOS package renders with installed Apple system fonts (PingFang SC, Songti SC, …) and does not carry the Linux score-font set, so glyph metrics legitimately differ from Windows/Linux pages of the same JPS. That is not a transcription defect. If a character is missing, record it and check **Help → Font status** in the desktop app.

If a wrapped reviewed document is used, preserve it and extract plain UTF-8 JPS to a different new path:

```sh
python3 '<skill-path>/scripts/linux-review.py' export \
  "$out/score-reviewed-document.jps" "$out/score-reviewed-plain.jps"
```

Keep the engine draft, issue JSON, reviewed document, plain JPS, rendered pages and report distinct. Compare the source hash at the end; macOS has no `sha256sum`, so use:

```sh
shasum -a 256 "$source"
```

## Handle conflicts and CLI errors

Exit codes are `0` success, `1` execution failure, `2` usage/invalid input, `3` missing capability, and `4` active-session conflict. Also check JSON `status`. The CLI refuses to overwrite existing output files.

- On `status: conflict` / exit `4` (`active_session_conflict`), read `error.conflict.path` and `error.conflict.sessions`, including each session's `windowLabel`, `documentName`, `dirty`, `conflictLatched`, and `processId`. If the conflicting document has unsaved edits, do not close it. Ask the user to save and close the named OctoPus session in the running app, or cancel. Once closed, verify the target paths are still unused and retry the same command once. Do not switch to desktop transcription because of a conflict.
- If an output target exists, choose another new output name or directory and retry without deleting or replacing the existing file.
- For other nonzero exit codes or `status: error`, report the returned code and message, fix the issue if possible, or stop. Do not retry through the desktop workflow.

## Older-package desktop workflow

Use this only when the selected app bundle is known to predate the public CLI or explicitly reports that headless commands are unsupported. Launch the app, choose **Import → JPG / PNG / PDF**, select the designated source, then choose **Transcribe → Transcribe New**. Save a distinct draft in the new workspace and review every PDF page. Compare Original Image/PDF with the SVG preview at readable zoom, export final PNG pages, and record visible findings if issue JSON is unavailable. Keep the source, hash, draft, reviewed JPS, exports and report distinct. This path is for older packages without the CLI, not for recovering from a failed CLI operation.
