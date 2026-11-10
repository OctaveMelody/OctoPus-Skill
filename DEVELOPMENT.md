# Development

The portable skill is in `.agents/skills/octopus-jps-transcription-review`. `SKILL.md` contains the agent workflow; `references/` contains notation, per-platform and visual-review guidance; and `scripts/` contains Windows PowerShell and POSIX (Linux/macOS) helpers for preparing a workspace, exporting plain JPS, and optionally installing the skill. OctoPus remains a separate installed or portable application. No OctoPus source checkout is required.

Run the local checks from the repository root in PowerShell:

```powershell
& .\tests\smoke.ps1
```

On Linux or macOS, run `python3 tests/smoke-posix.py`. It exercises `scripts/posix-review.py`, the helper shared by the Linux and macOS workflows.

The checks use generated temporary fixtures and cover PowerShell syntax, workspace creation, collision handling, JSON-wrapped/plain JPS export, source preservation and installation to an isolated destination. They do not exercise the OctoPus CLI or UI, nor measure transcription accuracy. For a full manual check, use a disposable score and a current package: verify `capabilities --json`, then run `transcribe`, `inspect` and PNG `export`; compare every source page/system with the generated pages and validate both plain and wrapped JPS. Check an older-package desktop fallback separately when one is available. Run this against the native package for each platform you claim support for — the Windows console launcher, the Linux AppImage/portable `usr/bin/octopus`, and the macOS app-bundle executable with `--headless`; a pass on one platform does not establish another. Test the host agent's actual skill discovery separately; syntax checks cannot establish Codex, Pi or OpenCode runtime compatibility.

Do not commit user-provided scores, source images, extracted diagnostics, screenshots, generated renders, local credentials, virtual environments or temporary review artifacts. The `.gitignore` excludes the normal output directory and JPS/review artifacts. Check the staged file list before publishing changes. The source-checkout-only helpers from earlier experiments are not part of this distribution.

Notation guidance is based on [Jianpu-Spec](https://github.com/yetist/jianpu-spec) and the current OctoPus manual. When behavior changes, check the actual installed/portable app and record its version; a parser accepting a command does not prove that it draws a symbol. Keep the skill host-neutral, and do not rely on private worker protocols or undocumented launcher arguments.
