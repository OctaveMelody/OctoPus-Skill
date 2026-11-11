# Jianpu-Spec v1.0 composing reference and OctoPus support

The upstream source is [Jianpu-Spec v1.0](https://github.com/yetist/jianpu-spec) (the reference was checked at revision `ada0f87`). An optional local copy may be kept anywhere; it is not required to run this skill. Upstream notation remains the source of truth for syntax. The support labels below describe the OctoPus parser/renderer checked when this reference was written and can change between versions. “Preserved, not rendered” means text may parse without an error but must not be assumed visible in the score.

## File structure and headers

| JPS feature | Jianpu-Spec rule | Current OctoPus behavior |
|---|---|---|
| Text file / header and body | A score has descriptive header lines followed by Q music and C lyric lines. | Implemented. JPS is ordinary UTF-8 text; the document JSON wrapper is separate from `.jps`. |
| `V:` | Script/spec version identifier; use the documented version. | Generic header is preserved. |
| `B:` | Title; repeated values can supply subtitles. | Implemented; repeated B lines have title/subtitle layout. |
| `Z:` | Author/credit; may repeat. | Implemented; repeated Z lines render as credits. |
| `D:` | Key/tonic letter A–G with supported sharp/flat notation. | Implemented; maps to key/tonic display. |
| `P:` | Meter such as `4/4`; multiple/auxiliary meters may be listed. | Implemented; first meter is initial meter, later or local meter behavior is documented in the manual. |
| `J:` | Numeric tempo and/or descriptive tempo text. | Implemented as printed header text/tempo metadata; it does not play audio. |
| `X:` | Optional score serial/sequence number in the spec. | **Preserved but inert:** generic header parsing accepts it, but OctoPus does not render the value. It is not a voice index. |
| `#` comment | A whole source line beginning with `#` is a comment. | Implemented. `#` after a note is an accidental token, not a line comment. |
| Blank source line | Separates body groups/systems. | Implemented as a system break within a page; empty groups do not create empty systems. |
| `[fenye]` | Manual page delimiter. | Implemented as a case-sensitive, standalone line in the JPS `code`. Do not change case or place it inside a Q/C line. |
| `Q:` / `C:` | Music and lyrics; lyrics attach to music rows. | Implemented. Numbered Q/C prefixes and named voices are supported by the implementation. |

## Music tokens

| Notation | Meaning | Current OctoPus behavior |
|---|---|---|
| `1`–`7` | Scale degrees; pitch is relative to the declared key/context. | Implemented. They are not absolute MIDI note numbers. |
| `0`, `8`, `9` | Visible rest, hidden rest/layout slot, rhythm X. | Implemented. `8` occupies rhythmic/layout space without printing a note. |
| `'`, `,` | Raise/lower octave; repeat marks for larger octave shifts. | Implemented. Preserve the number and direction of octave marks. |
| `/`, `.`, `-` | Shorten duration, dotted duration, extend a sounding note. | Implemented, including supported combinations. `-` is not a new lyric-bearing attack. |
| `#`, `$`, `=` | Sharp, flat, natural accidental. | Implemented before/after note forms supported by the parser. |
| `&name` | Named dynamics, tempo/ornament and other symbols listed in the spec tables. | The parser accepts generic names, but visible drawing is partial. Use the manual's rendered sample/status table for current support; do not infer a visible glyph from successful parsing. |
| `<`, `>`, `!`, `+` | Crescendo/decrescendo spans, end marks and vertical adjustment. | Implemented. `+` modifies documented constructs; keep it attached as the grammar requires. Verified on the current renderer: the bare span form (`5< … 4!` or `5> … 4!`) draws the hairpin converging toward the `!` host, while the code-after-a-note form `5&gt … 4!` parses with no visible span. Prefer bare span markers when the source hairpin must be visible. |
| `[..]`, `[h..]` | Pre-grace and post-grace notes. | Implemented. Grace notes have their own duration rules in the manual/spec. |
| `(...)`, `(y...)` | Slur/tie spans and tuplets. | Implemented, including nested/cross-row spans where valid. Do not confuse a music slur with lyric grouping. |
| `|`, `||`, `||/`, `|:`, `:|`, `:|:` and documented variants | Barline/final/repeat boundaries. | Implemented, including hidden `|/` (no barline width) and `|*` (invisible spacing slot). |
| `[]` at barlines | Volta/house-jump starts, ends, labels and adjustments. | Implemented. Labels/marks print but do not execute playback routes. |
| `|"p:n/d"` | Temporary meter change attached to a barline. | Implemented; the current meter continues according to OctoPus behavior across rows until changed again. |
| `{bz}`, `{dsb}` | Temporary accompaniment/voice blocks. | Implemented by current parser/layout. |
| `"text"` in a Q line | Note annotation. | Implemented; quote and attachment position matter. |
| `~`, `^` | `~` joins neighboring notes into one beat group; `^` forces a group boundary after its host. | Implemented as custom beat grouping. A music `~` host also activates tie-aware grouping for following short notes in the renderer; it does not change the written note values and is distinct from parenthesized `(…)` slurs and lyric `~`. |

## Lyrics

| Notation | Jianpu-Spec rule | Current OctoPus behavior |
|---|---|---|
| `C:` | Lyric row aligned with preceding Q/music row; multiple verses may follow. | Implemented, including numbered lyric voices. |
| CJK characters | One Chinese character per note/slot. | Implemented; compare carefully when there are hidden rests, skips or melismas. |
| `@` | Skip one note/lyric slot. | Implemented. It is not itself a sung syllable. Alignment cannot be derived by counting note slots by hand: skips interact cumulatively with melisma groups, slurs and lyric `~`, and lyric glyphs are not reliably centered under their noteheads, so measuring glyph positions on scaled crops cannot establish a slot map either. Treat a draft lyric row that renders as a visual match to the source as correctly placed and keep its `@`/`~` structure; change character content without re-flowing placement, and validate any placement change by comparing the newly rendered row beside the source page at matched scale. |
| `~` in lyrics | Join adjacent characters/syllables to one note or grouping. | Implemented; lyric `~` is distinct from its music-line meaning. |
| `/` | Separate English words/syllables and clarify mixed-language boundaries. | Implemented. English syllable-to-note assignment is not equivalent to one letter per note. |
| Punctuation and full-width space | Preserve meaningful punctuation/spacing conventions. | Implemented according to current renderer behavior; inspect the rendered result. |
| `"text"` at a C-line start | Quoted lyric annotation/verse label. | Implemented as a lyric annotation, but OctoPus removes ordinary half-width spaces from its payload and preserves `_` literally. |
| `_` inside quoted lyric annotation | Spec convention for a space where a literal source space cannot be used. | **Not implemented as a conversion:** OctoPus displays `_` rather than a space. If this convention is needed, record the limitation and do not silently claim parity. |

## Symbol rendering gaps to remember

The bilingual manual includes a current-OctoPus preview for each listed command. At the checked-in
renderer revision, `&cresc`, `&sf`, `&fp`, `&sfp`, `&tempo`, `&a tempo`, `&zy`, `&dy`, `&hx`, `&xby`,
`&cy`, `&xby+`, and `&cy+` add no visible mark; `&sby+` uses the base `&sby` shape. `&fine` and
`&dc.` print text without a dedicated glyph. `&sbf` prints literal `sbf` and does not position the
voice brace. The `&lt`/`&gt` span codes parse without drawing a hairpin; use the bare `<`/`>`
span form instead. The other documented symbols and terms are shown individually in the manual table.
These are renderer limitations, not reasons to rewrite or omit a symbol that is clearly present in
the source score.

## Scope and legacy material

- Jianpu-Spec chapter 05 is feedback/suggestions and historical contact information, not additional JPS grammar. Do not copy personal contact details into a score or manual.
- The spec mentions MIDI/audio playback and numeric volta labels as useful for playback. Current OctoPus can print notation but does not provide MIDI/audio playback or execute repeats.
- Unknown generic header names may be retained without being rendered. `Y:`/`S:` in examples and `X:` must not be assumed to have visual effect unless OctoPus documentation/implementation says so.
- A successful parse checks syntax and structural recoverability. Only a page-by-page comparison against the source can establish transcription fidelity.
