# Retranslation risk register

Severity describes potential impact, not a measured probability. “Confirmed” refers to inspected source; proposed changes and runtime consequences still require validation.

| Risk | Severity / evidence | Mitigation and release gate |
| --- | --- | --- |
| New scroll names cannot be entered completely | High; confirmed eight-character editor and spelling layout | Implement bounded full-name entry with storage/display/persistence support, or explicitly reduce scope to documented aliases. |
| Wrong or missing Blank Scroll effect | High; confirmed separate text table, positional ID arithmetic, eight-byte prefix success | Explicit alias-to-effect mappings and exact bounded matching; run all positive, collision, and negative cases. |
| Hidden scroll regression | High; confirmed Massacre slot and separate six-character Haven checks | Keep legacy aliases and special action paths; test reading, throwing, and ground protection independently. |
| Save or item data corruption | High if extending name storage; existing eight bytes are split across item arrays | Trace allocation, copying, freeing, and serialization before extension. Test old saves and new save round trips; never overwrite adjacent fields based on assumed free space. |
| Old written scrolls stop working | High; source stores and later resolves spellings | Retain old aliases and any required format migration. Ordinary item-ID stability alone does not protect Blank Scrolls. |
| Incorrect descriptions imported from Shiren 6 | High; different games and incomplete identity evidence | Verify SFC effects, values, durations, targeting, and restrictions. Write adapted prose when needed. No balance changes to fit descriptions. |
| False item equivalence | Medium–high; names and constant symbols use different conventions | Match Japanese identity and effect; keep unresolved/SFC-specific entries visible in the glossary. Preserve meat, story pottery, and quest objects. |
| Text-bank overflow or wrong lookup bank | High; confirmed two-byte `TextPointerTable` entries and text-ID bank thresholds | Measure bytes in the linked ROM; preserve or deliberately revise `Data_ff1075` and all consumers when relocating text. Inspect bank transitions and end-of-bank capacity. |
| Existing cross-bank string breaks | High; `Text1879` starts before the explicit bank `$3F` switch and continues at `$FF0000`; threshold is `1880` | Verify actual placement and continuity after all earlier text growth. Do not move just the threshold or bank directive. Assembly success alone does not prove the renderer will cross the boundary correctly. |
| UI clipping or corrupted composition | Medium–high; renderer has no word wrapping per existing fixes | Measure rendered width with counts, charges, upgrades, curse/seal markers, and category labels. Test every relevant window rather than using a universal character-count limit. |
| Control-code damage | High; custom stringmap and text commands | Preserve `@`/`endtext`, `\l`, `strvar`, `numvar`, `textfunction`, and message flush behavior. Avoid global text replacement that changes commands. |
| Equipment-effect overlap returns | Medium; `Text1353` documents single-line seal constraint | Keep short effect descriptions single-line; test 12 seals using existing seal stress tooling. |
| Mixed terminology teaches wrong actions | Medium; literal names, hints, categories, and unidentified appearances are distributed across files | Update all functional references in project one. Review plurals and names split by line-break commands. |
| Debug/testing blind spots | Medium; unused/dummy slots have names and sometimes effects | Preserve table cardinality; use debug item selection to cover hidden entries without adding them to normal spawn tables. |
| Source/version drift | Medium; community pages are not an official complete localization dump | Record final English platform/version and direct spelling evidence. Treat candidate mappings as provisional until checked. |
| Copying modern description prose into a distributed patch | Potentially high; scope depends on text reused and distribution | Track provenance and applicable reuse permissions before importing a substantial description corpus. Prefer independently written, SFC-accurate descriptions; that does not by itself settle the patch's overall rights position. See the source note below. |
| Existing fixes regress | Medium; `CHANGELOG.md` records fragile message flush, menu width, seal, ranking, and sign behavior | Recheck those cases after length changes, including all four ranking screens. |
| Patch applied to the wrong base | High impact; addendum currently requires the Aeon Genesis-patched ROM | Record base/output hashes and generate the patch from the intended base. Keep installation instructions aligned with the chosen release artifact. |

## Bank and encoding details

`text.asm` starts in ROM bank `$3E` (`$FE` CPU bank). `TextPointerTable` uses `.dw`, so it stores only low 16-bit addresses. `Data_ff1075` contains `1880` and `$FFFF`; lookup routines in `code/bank_04.asm` derive the bank from the text ID. This is not a relocation scheme where arbitrary strings can move independently without updating lookup logic.

The explicit switch to bank `$3F` is inside `Text1879` in `text/dialogue.asm`. Old address comments are historical, not a current free-space measurement. The end of the text build also contains leaderboard helper code/data, so prose growth must account for those occupants. Baseline `text.asm` assembled successfully during this audit; no full link, headroom measurement, or cross-bank emulator validation was performed.

`macros/text.asm` uses `data/mainFontMap.tbl`; zero encodes a space, letters have custom byte values, and control codes are separate from text. UTF-8 file length and ordinary ASCII string operations are unsuitable for determining ROM size or scroll matching. Canonical punctuation must exist in both the font map and input keyboard. Glyph support does not automatically imply keyboard support.

## Release blockers versus follow-up work

Block project-one release on unresolved mappings for changed items, unusable new scroll names, broken legacy scroll aliases, incorrect hidden effects, unsafe storage changes, bank/layout failures, or gameplay instructions that disagree with the accepted input. Block any claim of save compatibility until old-save and new-save round trips pass.

Full narrative polish can wait for project two. Exact official wording verification is still required before calling a candidate name an official Shiren 6 match. Descriptions that mention renamed items or teach Blank Scroll spelling need their minimal consistency edits in project one.

No recommendation to require a fresh save is established by this audit. The existing changelog's leaderboard caveat is separate from the new translation's compatibility questions; it neither proves nor disproves that a naming-only patch will preserve ordinary inventory saves.

For the description-copying risk, the [U.S. Copyright Office's reuse FAQ](https://www.copyright.gov/help/faq/faq-fairuse.html) explains that fair use depends on circumstances and has no automatic permitted word count or percentage. This is a distribution issue to assess for the intended jurisdictions, not a legal determination about this patch or a blocker to this documentation audit.
