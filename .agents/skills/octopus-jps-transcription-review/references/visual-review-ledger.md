# Visual comparison ledger for JPS transcription

Use this checklist for the first draft review and again for the final rendered JPS. The goal is to prove that every visible system was inspected, not to recreate the source's exact spacing.

## Set up the comparison

1. Open the source page beside the matching OctoPus-rendered JPS page. In OctoPus, maximize the window if useful. Fit-to-page is for orientation; zoom until individual note marks and lyric positions can be read, then compare one printed system at a time. If necessary, make enlarged inspection crops with enough vertical overlap to include both the notes and their lyrics; keep the original unchanged.
2. Number pages and systems in source order. Record the first and last lyric/heading cue for each system so similar repeated phrases cannot be mistaken for one another.
3. Read the source image and the rendered notation together. The JPS text helps locate tokens, but the rendered output is the view to compare with the score. A syntax-clean parse is not evidence of a correct transcription.

Before the system pass, compare all printed header information with the render: title, subtitles, credits, key, meter and tempo. In particular, do not assume that every repeated header line will appear in the current renderer; check it. If long header text overlaps the score or credits, preserve the information in the JPS and report any text that cannot be displayed clearly.

## Check each system

For each source/rendered system pair, account for:

- **Coverage and structure:** inventory all source systems before trusting detected rows; compare opening and ending cues, not just counts, since one missing system can be offset by another split row. Check barline and repeat boundaries and look for lyrics misclassified as titles or credits, missing measures, rests, pickups, or phrases.
- **Events and pitch:** compare each note/rest in order and count events within each bar. Check scale degree, accidental on the intended note, octave dot direction/count, and natural notes where the key signature could mislead.
- **Rhythm:** verify each beam/slash, augmentation dot, and continuation dash on the correct note. Distinguish an octave dot from a duration dot. A continuation dash sustains the preceding note; it does not create a new lyric-bearing attack.
- **Connections and marks:** compare each slur/tie's start and end, fermata, ornament, and printed bracket separately. In particular, do not use an ordinary parenthesized slur/tie where the source has accompaniment parentheses (`&zkh` / `&ykh`); check the opening and closing extent.
- **Lyrics:** map each printed character or syllable to its note/slot in order. Account for every `@` skip, sustained-note melisma, punctuation, and lyric continuation. Do not infer alignment from total lyric length or from a neighboring repeated verse; confirm it against the actual noteheads and lyric positions.
- **Variant repeats:** revisit every repeated melody when its notes, lyrics, articulation, or ending differ. Never copy a prior system without checking the corresponding source system.

Inventory accompaniment parentheses across the entire score, including instrumental introductions and passages that cross Q rows. Record each opening and closing endpoint separately and check that both characters actually appear in the render; a matching pair elsewhere does not cover the opening. Ordinary music parentheses create a slur and may parse cleanly while leaving the printed accompaniment parentheses absent. In one checked introduction, `0&zkh` opens the printed parenthesis on a rest and `5, - - - &ykh` closes it after the sustained ending in a later Q row. Use the source to select the endpoints and verify the output rather than copying this placement into unrelated scores.

Inspect attachment as well as the symbol name: in a checked OctoPus case, `- &ykh` parsed as a separate decoration token, while `-&ykh` attached it to the preceding continuation dash. Both parsed without diagnostics. Compare the parsed token and rendered position against the source before choosing the form. Also recheck grouping when spaces around notes, symbols or row-start barlines change: adjacency can change `attached_to_previous` even when pitches and durations remain the same.

When the source has a mark across a system break, inspect both ends in the final render. First check the documented same-voice cross-row span. If its fragments are absent, try an explicit split with row-end and row-start continuations, then render again. For example, one checked case ends a row with `(6,/ |)/` and begins the next with `(|/ 6,/)`; the hidden row-start barline and the separate fragments produced the visible continuations. Verify the actual source endpoints, rhythm, barlines and parser diagnostics before adopting this pattern; it is not a universal replacement for a continuous span. Only report a renderer limitation after checking applicable syntax and alternatives.

For successive ties sharing a note, trace each arc independently, including its closing parenthesis. For example, a checked sustained passage rendered the two intended arcs with `(5 - - (5/) | 5)`; `(5 - - (5/ | 5))` instead extended the inner arc to the later note. Compare each curve with the source after editing. The current support matrix identifies breath mark `&hx` as accepted but not visibly rendered: retain a supported source mark and disclose the missing visual output.

Use the current notation rules in `jps-spec-coverage.md` when deciding how a source mark maps to JPS. When an image is too blurred to settle a detail, record the alternatives and leave the reading marked uncertain instead of silently normalizing it.

## Coverage record

Keep a compact ledger in the review report. One row per printed system is sufficient when the row is fully checked; split it by bar or phrase if any mismatch is hard to localize.

| Page/system and source cue | Bars/events checked | Pitch, accidental, octave | Rhythm and connections | Lyric-to-slot alignment | Status / evidence |
|---|---|---|---|---|---|
| 1/1 — opening through “…” | bars …; … events | matched / corrections | matched / corrections | instrumental / matched | matched, corrected, or uncertain; note render/page cue |

Use only these statuses:

- **Matched:** source and final render agree across the row.
- **Corrected:** describe the concrete source-to-JPS correction and confirm it in the final render.
- **Uncertain:** name the unresolved symbol/slot and the plausible readings.

Do not close review while any source system lacks a ledger row or any row is left unexamined. After editing, perform a fresh pass from the opening system through the final bar; verify the accepted correction list against the render and source. A full-page glance is not a substitute for this pass.
