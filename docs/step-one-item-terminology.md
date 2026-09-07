# Step one: item terminology

Status: implementation audit and proposed specification, not a completed retranslation.

## Scope and source policy

Use the English Shiren 6 name when the underlying item is a defensible match. Match by Japanese identity from `constants/items.asm` and by actual effect, not by similar English words or the existing assembly symbol. The constants already use another naming vocabulary: for example, `Item_Mastersword` currently displays “Dotanuki.” Renaming the constant would not rename the item.

The CSV's `candidate` status means the target name appears in the cited Shiren 6 community reference and its association with this SFC item is an audit inference. It still requires identity, official English spelling, and UI verification. `review` means no defensible target was established here; it does not prove that the item is absent from every Shiren 6 version or DLC. `protected` means retain the slot and inspect its special role before editing. The inventory is complete; the translation decisions are deliberately not presented as complete.

For final terminology, record the English game's platform/version and verify against its in-game item notebook or another direct localization source. Community references are useful indexes but are not a substitute for that final check. Do not copy their explanatory prose into the patch.

Reference pages consulted on 2026-09-07 (the CSV cites the relevant category per candidate): [weapons](https://sharksnack.github.io/shiren-6/items/weapons/), [shields](https://sharksnack.github.io/shiren-6/items/shields/), [grass](https://sharksnack.github.io/shiren-6/items/grass/), [scrolls](https://sharksnack.github.io/shiren-6/items/scrolls/), [staves](https://sharksnack.github.io/shiren-6/items/staves/), [bracelets](https://sharksnack.github.io/shiren-6/items/bracelets/), [pots](https://sharksnack.github.io/shiren-6/items/pots/), [food](https://sharksnack.github.io/shiren-6/items/food/), and [projectiles](https://sharksnack.github.io/shiren-6/items/projectiles/).

## What changes in project one

| Surface | Source | Required work |
| --- | --- | --- |
| Identified names | `text/itemnames.asm`, `Text764`–`Text995` | Resolve each inventory row, then change display text while preserving IDs, labels, order, and terminators. |
| Unidentified names | Same file, `Text996`–`Text1147` | Review category suffixes and appearance vocabulary. Preserve the number/order of slots and identification randomization. Do not equate an appearance name with a real item. |
| Bounds sentinel | Same file, `Text1148` | Preserve the special role of “Item Number Over”; not a normal item. |
| Category labels | `text/leaderboard.asm`, `text/debugitemmenu.asm`, menu/message text | Review Herb/Grass, Bracer/Bracelet, Food/Onigiri, Staff/Staves. Player-facing text can change without renaming assembly identifiers. |
| Scroll spells | `text/leaderboard.asm`, `Text1202`–`Text1235` | Update accepted spell vocabulary and retain effect mappings/legacy aliases; see the dedicated Blank Scroll specification. These are gameplay data despite the filename. |
| Scroll hints | `text/itemdescriptions.asm`, `Text1445`–`Text1470` | Update every `Scribe:` instruction to an accepted spelling at the same time as the names. Clarify the Blank Scroll description, `Text1463`, to match implemented input. |
| Literal item references | `text/dialogue.asm`, `text/dungeonmessages.asm`, `text/leaderboard.asm`, `text/signs.asm` | Replace approved item terms in context. Handle names split by `\l`, punctuation, and plurals. Reflow affected lines. |
| Formatting and lookup | `text.asm`, `code/bank_04.asm`, `data/mainFontMap.tbl`, `macros/text.asm` | Validate encoded lengths, rendered widths, bank allocation, pointer lookup, and control codes. |
| Blank Scroll behavior | `code/bank_03.asm`, `code/bank_04.asm` | Implement full-name recognition and compatibility as described in `blank-scrolls.md`. |

There are 232 ID slots, not 232 ordinary obtainable items. The constants mark 95 as unused or dummy; additional special entries include money, a null slot, objectives, and N'duba. In particular, dummy `$62` has the “Massacre” spell and a real description. Do not delete placeholder entries or automatically expose them as ordinary items.

The normal description sequence begins at `Text1359`, corresponding to item `$00`, and continues through `Text1589` for `$E6`. `$E7` has no separate description label in this sequence. `Text1339`–`Text1358` are equipment effect/seal descriptions; `Text1338` is a PPU version string. A rewrite of the entire file as though it contained only item prose would be incorrect.

## Decisions to resolve before editing

- **SFC-specific items:** Bufoo's cleaver/staff and monster meat are not automatically Peach Club/Peach Staff/Peach Bun. Gaibara's pottery and story objectives need their own conventions. Keep these on the exception list until a source-backed name is chosen.
- **Similar effects are insufficient:** the current Leather Shield should not simply become Shield of Sating, nor Echo Shield become Shield of Negation, based only on a partial effect match. Gilded Shield has Japanese identity `見かけだおしの盾`, so “Golden Shield” would also be an unsafe guess.
- **Terminology shared with prose:** resolve Bufoo/Bufu, Todo/Thiefwalrus, monster families, hunger/fullness, statuses, and seal/rune terminology. Project one should make necessary item-reference substitutions; broader character and narrative naming belongs in project two.
- **Full Blank Scroll names:** the recommended target accepts the displayed Shiren 6 name and the name without “Scroll,” plus existing spell aliases. Keeping only eight-character abbreviations is a smaller fallback, but does not fully meet the requested new-name behavior.
- **Descriptions:** defer full prose rewrites to project two, but update names and functional instructions immediately. If descriptions must ship with project one, explicitly include their SFC mechanics review and layout testing in that project's scope.

## Concrete consistency searches

Known dependent passages include Sabu's Blank Scroll tutorial near `text/dialogue.asm:5151`, the warning about Genocide Scrolls near line 3648, and Purify Scroll references near line 5109. Search both whole names and distinctive stems because embedded line breaks split names. Review matches as sentences: a character saying a purification spell is not necessarily naming an item.

Food references also live outside item names: `text/dungeonmessages.asm` contains both “Big Rice Ball” and “Large Rice Ball,” transformation messages, eating messages, and spoilage messages. Leaderboard death text refers to a rotten Rice Ball. Category changes must cover these surfaces.

Keep a glossary keyed by item ID with current name, approved full name, source/version, encoded byte count, rendered width, Blank Scroll aliases, and required exceptions. The CSV is its starting inventory. Before implementation, add approval/evidence and layout results rather than treating candidate names as ready to ship.

## Implementation order and completion criteria

1. Resolve the glossary and exceptions, including every reachable special scroll. Preserve numeric IDs and text-ID positions.
2. Establish baseline screenshots and behavior for item menus, descriptions, Blank Scrolls, and existing saves. Measure bank usage and the longest decorated names.
3. Implement the Blank Scroll input/resolver changes with the new glossary; update display names, hints, labels, and literal references together.
4. Assemble and link both normal and debug ROMs. Inspect text-bank transitions and any relocated code/data. Do not treat the original matching-ROM SHA1 as the expected result for an intentional translation change.
5. Exercise every changed item category in inventory, shops, floor prompts, pots, equipment, and rankings. Include arrows with counts, charged staves, pot capacities, upgrade values, curses, seals, and unidentified/custom names.
6. Complete the Blank Scroll matrix and save round trips in `blank-scrolls.md`. Recheck the existing text fixes in `CHANGELOG.md`.
7. Record final decisions, screenshots, ROM/input hashes, and patch application instructions. A documentation audit is not evidence that a playable translation patch passed these checks.

## Project two: descriptions and prose

Start with item descriptions and short equipment-effect strings, then move to gameplay messages/tutorials and finally dialogue/signs. Keep SFC effect amounts, durations, targeting, curses, identification, capacity rules, and special conditions authoritative. The Shiren 6 reference describes Preservation Pot handling and a capacity limit of six; those details cannot establish this SFC engine's rules. Similarly, the Shiren 6 Blank Scroll notebook requirement is not evidence for adding that requirement here. [Shiren 6 pots](https://sharksnack.github.io/shiren-6/items/pots/), [Shiren 6 scrolls](https://sharksnack.github.io/shiren-6/items/scrolls/).

Use independently written descriptions in the chosen modern terminology when mechanics differ. Exact description transplantation is only appropriate after verifying identical behavior and fitting the SFC text engine. This audit does not authorize changing game balance to make imported descriptions true.
