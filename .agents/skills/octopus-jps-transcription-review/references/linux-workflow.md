# Linux workflow

The public CLI is the default for current OctoPus packages. It uses the local transcription/parser/render engine and does not contain or invoke an LLM. The active vision-capable host agent must still compare every source page and rendered page and correct the JPS.

## Package and prerequisites

Linux releases are `OctoPus_<version>_<arch>_linux.AppImage` packages or the complete portable tree whose executable is `usr/bin/octopus`. Both accept `--headless`; there is no separate console launcher.

- The executable links the desktop GUI libraries, so the host GTK/WebKit runtime packages are required even for headless commands (on Debian and Ubuntu: `libgtk-3-dev`'s runtime libraries and `libwebkit2gtk-4.1`). A launch failure that names a missing shared library is an installation blocker to report, not an older-package signal.
- PDF transcription needs Poppler's `pdfinfo`, `pdftotext` and `pdftoppm` on `PATH` (`sudo apt-get install poppler-utils`); the AppImage does not bundle them.
- Linux packages ship the verified score-font set under `usr/lib/OctoPus/fonts/` beside the worker. Keep the tree together, and expect legitimate glyph-shape differences against macOS or Windows pages of the same JPS; judge musical accuracy from the notation, not the typeface.

## Detect the public CLI

Resolve the selected AppImage or portable executable to an absolute path. The AppImage and portable program both receive `--headless` before the CLI command:

```sh
app='/absolute/path/OctoPus.AppImage'
"$app" --headless capabilities --json

# Or, for the executable in a complete portable package:
octopus='/absolute/path/to/portable/usr/bin/octopus'
"$octopus" --headless capabilities --json
```

This is a non-mutating capability query. The successful JSON object has `status: "ok"`; it is written to stdout, while progress and worker messages go to stderr. Check its exit code and that `schema_version` is compatible with major version `1` and `commands` lists the needed operations. Record `product_version`. For image/PDF transcription, confirm `transcription_available`; for PDF, also confirm `pdf_transcription.available` and `transcription_formats` includes `pdf`; for comparison images, confirm `png_export_available` and `export_formats` includes `png`.

Use a short process timeout only for this initial AppImage capability probe, because older AppImages may ignore `--headless`. If a valid capability object is returned, use the CLI. If the package is known to predate the CLI or explicitly reports that the command is unsupported, continue with the older-package desktop workflow. A timeout or launch/runtime failure is not proof of an older release; report it and resolve the launch problem. Do not repeat an unsupported probe, and do not switch to the desktop workflow after a CLI operation has started and failed. If FUSE is unavailable and the AppImage supports extract-and-run, set `APPIMAGE_EXTRACT_AND_RUN=1` for the capability probe and subsequent commands; report other launch failures.

## Prepare the workspace and transcribe

Create a new workspace and record the source hash:

```sh
python3 '<skill-path>/scripts/posix-review.py' prepare '/absolute/path/score.pdf'
```

Use the helper's returned `OutputDirectory` and `SourceSha256` fields. Select new paths for the draft and issue JSON, then run the CLI synchronously. Keep stdout separate from stderr and check both the exit code and JSON `status`:

```sh
out='/absolute/path/to/output/score'
source='/absolute/path/to/score.pdf'
draft="$out/score-draft.jps"
issues="$out/score-issues.json"

result=$("$app" --headless transcribe "$source" --out "$draft" --issues "$issues" --json)
code=$?
if [ "$code" -ne 0 ]; then printf '%s\n' "$result" >&2; exit "$code"; fi
printf '%s\n' "$result"
```

The successful JSON result has `status: "ok"` and includes absolute `draft_path` and `issues_path`, `page_count`, `issue_count`, and structured `issues`. Check `status` as well as the process exit code. The separate issue file has `status: review_required`. `page_count` counts source pages processed. For a PDF, only start after `transcription_available` and `pdf_transcription.available` are true; if `pdf_transcription.missing` lists required tools, report the capability gap before starting. Confirm the returned source page count against the complete PDF. Read every PDF page in order during visual review.

## Inspect and export rendered pages

`inspect` and `export` accept plain JPS or a JSON-wrapped OctoPus document with `code` and page settings. `inspect` returns `document_name`, `json_wrapped`, `encoding_repaired`, `source_offset_unit`, `parse_diagnostics`, `score_diagnostics`, rendered `page_count`, and `custom_markup_omitted`. Use its diagnostics to identify syntax problems. A clean parse does not establish musical accuracy.

```sh
inspect=$("$app" --headless inspect "$draft" --json)
code=$?
if [ "$code" -ne 0 ]; then printf '%s\n' "$inspect" >&2; exit "$code"; fi
printf '%s\n' "$inspect"

draft_pages="$out/draft-pages"
mkdir "$draft_pages"
export=$("$app" --headless export "$draft" --format png --out-dir "$draft_pages" --dpi 300 --json)
code=$?
if [ "$code" -ne 0 ]; then printf '%s\n' "$export" >&2; exit "$code"; fi
printf '%s\n' "$export"
```

Successful `inspect` and `export` results have `status: "ok"`; check that status too. Use the absolute `outputs` paths and `page_count` and inspect every file. For PNG with multiple pages, files use the JPS filename stem with suffixes such as `_page_001.png`; a single page uses the unsuffixed stem. Keep the output directory and target files new; existing targets are never overwritten. After editing a separate reviewed JPS, run `inspect` and export the reviewed pages to a new directory. If `custom_markup_omitted` is true, record it and check for lost custom notation.

If a wrapped reviewed document is used, preserve it and extract plain UTF-8 JPS to a different new path:

```sh
python3 '<skill-path>/scripts/posix-review.py' export \
  "$out/score-reviewed-document.jps" "$out/score-reviewed-plain.jps"
```

The helper also copies plain JPS and refuses existing output paths. Keep the engine draft, issue JSON, reviewed document, plain JPS, rendered pages and report distinct. Compare the source SHA-256 at the end:

```sh
sha256sum "$source"
```

## Handle conflicts and CLI errors

Exit codes are `0` success, `1` execution failure, `2` usage/invalid input, `3` missing capability, and `4` active-session conflict. Also check JSON `status`. The CLI refuses to overwrite existing output files.

- On `status: conflict` / exit `4` (`active_session_conflict`), read `error.conflict.path` and `error.conflict.sessions`, including each session's `windowLabel`, `documentName`, `dirty`, `conflictLatched`, and `processId`. If the conflicting document has unsaved edits, do not close it. Ask the user to save and close the named OctoPus session or cancel. Once closed, verify the target paths are still unused and retry the same command once. Do not switch to desktop transcription because of a conflict.
- If an output target exists, choose another new output name or directory and retry without deleting or replacing the existing file.
- For other nonzero exit codes or `status: error`, report the returned code and message, fix the issue if possible, or stop. Do not retry through the desktop workflow.

## Older-package desktop workflow

Use this only when the selected AppImage/portable package is known to predate the public CLI or explicitly reports that headless commands are unsupported. Launch its desktop app, choose **Import → JPG / PNG / PDF**, select the designated source, then choose **Transcribe → Transcribe New**. Save a distinct draft in the new workspace. Review every PDF page. Compare Original Image/PDF with the SVG preview at readable zoom, export final PNG pages, and record visible findings if issue JSON is unavailable. Keep the source, hash, draft, reviewed JPS, exports and report distinct. This path is for older packages without the CLI, not for recovering from a failed CLI operation.
