# OctoPus transcription review skill

This Windows skill guides a vision-capable coding agent through transcribing a Jianpu image or PDF with [OctoPus](https://github.com/OctaveMelody/OctoPus), checking the rendered score against the original, and producing a corrected JPS file and review report. It uses the installed OctoPus desktop application or its complete portable package; it does not require OctoPus or OctoPus-dev source repositories, WSL, Python, or a network service at runtime.

## Requirements

- Windows with PowerShell 5.1 or newer and an installed OctoPus desktop app, or the complete Windows portable package. Download OctoPus from its [official releases](https://github.com/OctaveMelody/OctoPus/releases).
- Codex, Pi, or OpenCode with image inspection and desktop control, or a user who can carry out the desktop interactions. A vision-capable model is needed for the score comparison.
- A user-designated PNG, JPG/JPEG, or PDF. The transcription and review remain local. OctoPus does not automatically execute repeat or playback routes.

## Install and use

Clone this repository, open it as the working directory in your agent, and ask the agent to transcribe a specific source file. The project skill lives at `.agents/skills/octopus-jps-transcription-review/SKILL.md`.

```powershell
git clone https://github.com/OctaveMelody/OctoPus-Skill.git
Set-Location OctoPus-Skill
```

For user-level installation, the optional helper copies the skill to `%USERPROFILE%\.agents\skills` and refuses to overwrite an existing copy:

```powershell
& .\.agents\skills\octopus-jps-transcription-review\scripts\install-user-skill.ps1
```

The helper also accepts `-Destination` for an agent-specific skills directory. Restart or reload the agent as needed. Refer to the host's documentation for its discovery rules: [Pi](https://pi.dev/docs/latest/skills) and [OpenCode](https://docs.opencode.ai/docs/skills/) document the shared `.agents/skills` layout. The skill follows the common directory-based `SKILL.md` format.

The workflow creates a collision-safe folder in `output` beneath the agent's current working directory, retains the original source, and saves a separate draft, reviewed JPS, rendered pages and report. The desktop app may save a JSON-wrapped `.jps`; the supplied helper can extract plain JPS to a separate file. See [the Windows workflow](.agents/skills/octopus-jps-transcription-review/references/windows-workflow.md) for details.

Review every result against the original. Parser success does not establish musical accuracy, and some symbols may be accepted without being drawn. When a source or symbol is unclear, the report records that uncertainty.

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for the repository layout and local checks. Generated scores, renders, source images and issue reports belong in ignored output folders and are not distributed with this repository.

## License

GPL-3.0-or-later; see [LICENSE](LICENSE). Jianpu-Spec and OctoPus are separate projects with their own licenses.
