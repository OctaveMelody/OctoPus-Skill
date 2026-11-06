# Windows desktop workflow

Use an installed OctoPus desktop application or the executable in its complete portable folder. This workflow does not require an OctoPus or OctoPus-dev source checkout, WSL, Python, Poppler, a browser, or a network service. The host must be able to inspect images and control the desktop app; if it cannot, ask the user to perform the UI interactions and describe what remains unverified.

## Prepare the work folder

From a writable working directory, run the workspace helper from the skill's `scripts` directory:

```powershell
& '<skill-path>\scripts\new-review-workspace.ps1' -InputPath 'C:\Scores\example.jpg'
```

The helper creates a unique folder under the current directory's `output`, prints its path and the source SHA-256, and never changes the source. Pass `-OutputDirectory` to select a different new folder. Record the hash in the review report and check it again at the end with `Get-FileHash -Algorithm SHA256`.

## Transcribe and review in OctoPus

1. Launch the installed app, or run `octopus.exe` from the complete portable folder. Choose **Import → JPG / PNG / PDF** and select the designated source. For a PDF, review all pages.
2. Choose **Transcribe → Transcribe New** and wait for the provisional score. Record displayed findings. Save a distinct draft in the new working folder before editing; do not replace an existing score.
3. Compare the Original Image/PDF and SVG preview panels side by side, zooming and scrolling one system at a time. Review the source, preview and lyrics using `visual-review-ledger.md`; edit the JPS source and save the result under a distinct reviewed name. If the app cannot export an issue JSON, describe the displayed findings and that limitation in the report.
4. Refresh the preview and use **Export → PNG** to save rendered pages. Inspect every final page beside the source again. Review parser warnings in the app, and do not treat a clean parse as proof of musical fidelity.

## Plain JPS and saved documents

OctoPus may save a `.jps` file as a JSON document containing a `code` field and page settings. Preserve that document when it contains useful layout settings. For a plain UTF-8 Jianpu-Spec JPS deliverable, extract its `code` field into a different, new file:

```powershell
& '<skill-path>\scripts\export-plain-jps.ps1' -InputPath 'C:\Scores\reviewed-document.jps' -OutputPath 'C:\Scores\reviewed-plain.jps'
```

The helper also accepts an existing plain JPS and copies its text. It refuses to overwrite a destination or source. Keep the app document, draft, exported pages and review report distinct. The desktop app's version and available diagnostics can differ between installations; record what was actually used. Do not call OctoPus's private worker protocol or treat undocumented desktop-launcher arguments as a CLI.
