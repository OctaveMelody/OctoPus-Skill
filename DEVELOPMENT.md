# Development

The portable skill is in `.agents/skills/octopus-jps-transcription-review`. `SKILL.md` contains the agent workflow; `references/` contains notation and visual-review guidance; and `scripts/` contains Windows and Linux helpers for preparing a workspace, exporting plain JPS, and optionally installing the skill. OctoPus remains a separate installed or portable application. No OctoPus source checkout is required.

Run the local checks from the repository root in PowerShell:

```powershell
& .\tests\smoke.ps1
```

On Linux, run `python3 tests/smoke-linux.py`.

The checks use generated temporary fixtures and cover PowerShell syntax, workspace creation, collision handling, JSON-wrapped/plain JPS export, source preservation and installation to an isolated destination. They do not exercise OctoPus UI automation or measure transcription accuracy. For a full manual check, use a disposable score and an installed OctoPus app to run the documented import, transcription, source/render review and PNG export workflow. Check all pages and both plain and wrapped JPS formats as applicable. Test the host agent's actual skill discovery separately; syntax checks cannot establish Codex, Pi or OpenCode runtime compatibility.

Do not commit user-provided scores, source images, extracted diagnostics, screenshots, generated renders, local credentials, virtual environments or temporary review artifacts. The `.gitignore` excludes the normal output directory and JPS/review artifacts. Check the staged file list before publishing changes. The source-checkout-only helpers from earlier experiments are not part of this distribution.

Notation guidance is based on [Jianpu-Spec](https://github.com/yetist/jianpu-spec) and the current OctoPus manual. When behavior changes, check the actual installed/portable app and record its version; a parser accepting a command does not prove that it draws a symbol. Keep the skill host-neutral, and do not rely on private worker protocols or undocumented launcher arguments.
