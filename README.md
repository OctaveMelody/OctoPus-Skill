# OctoPus transcription review skill

This Windows and Linux skill guides a vision-capable coding agent through transcribing a Jianpu image or PDF with [OctoPus](https://github.com/OctaveMelody/OctoPus), checking the rendered score against the original, and producing a corrected JPS file and review report. It uses the installed OctoPus desktop application or its complete portable package; it does not require OctoPus or OctoPus-dev source repositories, WSL or a network service at runtime. The Linux file helpers use Python 3.11 or newer.

## Requirements

- Windows with PowerShell 5.1 or newer, or Linux with Python 3.11 or newer. Current OctoPus packages provide the public CLI; older packages can use the desktop workflow. Download OctoPus from its [official releases](https://github.com/OctaveMelody/OctoPus/releases).
- Codex, Pi, or OpenCode with local file access and a vision-capable model. Desktop control is needed only for older packages without a detected CLI or when the user chooses the desktop route. OctoPus does not provide or invoke an LLM; the host agent performs visual review.
- A user-designated PNG, JPG/JPEG, or PDF. The OctoPus CLI processes files locally; visual review uses the host agent's vision-capable model. OctoPus does not automatically execute repeat or playback routes.
- When the host model is served by Strata, run this workflow in a single agent session; do not review scores in parallel sessions.

## Install and use

Clone this repository, open it as the working directory in your agent, and ask the agent to transcribe a specific source file. The project skill lives at `.agents/skills/octopus-jps-transcription-review/SKILL.md`.

```sh
git clone https://github.com/OctaveMelody/OctoPus-Skill.git
cd OctoPus-Skill
```

In PowerShell, `cd OctoPus-Skill` works as well.

For user-level installation, the optional helper copies the skill to `%USERPROFILE%\.agents\skills` and refuses to overwrite an existing copy:

```powershell
& .\.agents\skills\octopus-jps-transcription-review\scripts\install-user-skill.ps1
```

On Linux, open the cloned repository in the agent to use its project skill, or copy `.agents/skills/octopus-jps-transcription-review` to the user skill directory supported by the agent, without overwriting an existing copy.

The Windows helper also accepts `-Destination` for an agent-specific skills directory. Restart or reload the agent as needed. Refer to the host's documentation for its discovery rules: [Pi](https://pi.dev/docs/latest/skills) and [OpenCode](https://docs.opencode.ai/docs/skills/) document the shared `.agents/skills` layout. The skill follows the common directory-based `SKILL.md` format.

The workflow creates a collision-safe folder in `output` beneath the agent's current working directory, retains the original source, and saves a separate draft, reviewed JPS, rendered pages and report. The CLI's inspect/export commands accept plain and JSON-wrapped `.jps` documents; the supplied helper can extract plain JPS from a wrapped document. See the [Windows workflow](.agents/skills/octopus-jps-transcription-review/references/windows-workflow.md) or [Linux workflow](.agents/skills/octopus-jps-transcription-review/references/linux-workflow.md) for CLI discovery, command examples and the older-package UI fallback.

Review every result against the original. Parser success does not establish musical accuracy, and some symbols may be accepted without being drawn. When a source or symbol is unclear, the report records that uncertainty.

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for the repository layout and local checks. Generated scores, renders, source images and issue reports belong in ignored output folders and are not distributed with this repository.

## License

GPL-3.0-or-later; see [LICENSE](LICENSE). Jianpu-Spec and OctoPus are separate projects with their own licenses.
