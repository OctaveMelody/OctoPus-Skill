# Linux desktop workflow

Use the installed OctoPus desktop application, a complete portable folder, or an executable AppImage. A graphical desktop, image inspection and desktop control are needed; if the agent cannot operate the UI, the user may perform those interactions. The helper below uses Python 3.11 or newer, with no third-party modules. The transcription and rendering use the desktop app, not a source checkout or its private worker protocol.

## Prepare and launch

From a writable working directory, create a new output folder and record the source SHA-256:

```sh
python3 '<skill-path>/scripts/linux-review.py' prepare '/absolute/path/score.jpg'
```

The helper prints the source path, hash and a unique folder under the current directory's `output`. To choose a new output folder, add `--output '/absolute/path/new-folder'`; an existing folder is rejected. Recheck the source afterward with `sha256sum '/absolute/path/score.jpg'`.

Launch the installed application, the executable in its complete portable folder, or the AppImage selected by the user:

```sh
'/absolute/path/OctoPus.AppImage'
```

If the host lacks FUSE, an AppImage supporting the standard extract-and-run mode can be launched with `APPIMAGE_EXTRACT_AND_RUN=1 '/absolute/path/OctoPus.AppImage'`. This extracts temporary application files and needs adequate disk space; report launch failures rather than switching to another executable silently.

## Transcribe and review

1. Choose **Import → JPG / PNG / PDF**, select the source, then **Transcribe → Transcribe New**. Wait for the draft and record visible findings. Review every PDF page.
2. Save a distinct draft in the new workspace. Compare Original Image/PDF with SVG preview at readable zoom, system by system, using `visual-review-ledger.md`. Edit a separate reviewed copy and record corrections and uncertainty.
3. Refresh the preview, review warnings and export PNG pages. Make a fresh complete comparison of the reviewed output against the source. Preserve the draft and report unavailable diagnostics; successful rendering alone does not prove accuracy.

## Plain JPS

A saved `.jps` can be a JSON document containing `code` and page settings. Preserve the app document; export its code to a different new plain UTF-8 file with:

```sh
python3 '<skill-path>/scripts/linux-review.py' export '/path/reviewed-document.jps' '/path/reviewed-plain.jps'
```

The helper also copies plain JPS and refuses existing output paths. Keep the source, draft, app document, plain output, rendered pages and report distinct. Record the application version and actually available findings.
