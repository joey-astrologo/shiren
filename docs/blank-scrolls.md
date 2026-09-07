# Blank Scroll compatibility

## Current implementation: confirmed in source

`Item_BlankScroll` is `$68`. Inventory text is `Text868`; its description is `Text1463`. Accepted spell strings are a separate table in `text/leaderboard.asm`, beginning at `Text1202`, not the inventory-name table.

| Path | Evidence | Consequence |
| --- | --- | --- |
| Item naming UI | `code/bank_04.asm`, `func_C495CD` | Passes `$0008` as the input length to `func_C48FEC`; comment records an extension from six to eight. |
| Stored spelling | `code/bank_03.asm`, `@lbl_C30259`; `code/bank_04.asm`, `func_C49295` | Six characters occupy item-indexed arrays at `$7E8C8C`, `$7E8D0C`, `$7E8F0C`, `$7E8F8C`, `$7E8C0C`, `$7E8D8C`; characters seven/eight use `$7EFF00`/`$7EFF80`. |
| Load for recognition | `code/bank_03.asm`, `func_C3091F`; `func_C492B7` in bank 04 | Reconstructs eight bytes at `$7E9360`–`$7E9367`. This is spelling storage, not a permanent resolved effect ID. |
| Load for display | `code/bank_03.asm`, `@lbl_C33C42`; `func_C492AA` in bank 04 | Reads the same extended spelling. Writing, reading, and rendering all need coordinated changes. |
| Main spell lookup | `func_C3091F` | Tries text IDs `$04B2` through `$04CC` inclusive, i.e. `Text1202`–`Text1228`. On match returns `text_id - 1202 + $56`. |
| Monster House aliases | Same routine | Skips `Text1229`, tries `Text1230`–`Text1233`, and returns `$65`. |
| Final special aliases | Same routine | Tries `Text1234`–`Text1235` and returns `$6F`; both currently contain a line-break placeholder. |
| Compare | `code/bank_04.asm`, `func_C4C0E0` | Looks up the string through `TextPointerTable`, skips zero-byte spaces, applies an inherited character conversion, and uses `$FF` termination. This is not a normal ASCII comparator. |
| Eight-byte shortcut | `func_C492C6` | Increments X/Y after matching a character and returns success when Y reaches eight, without checking the remaining target string. Longer table strings can therefore match by prefix. |
| Special ground-effect checks | `code/bank_03.asm`, `func_C307C9` and `func_C30824` | Compare specifically with `Text1228` (`Haven`). They copy only six characters and place `$FF` at `$9366`, bypassing the two-character extension. |

The source does not justify promising case-insensitive behavior: uppercase and lowercase have distinct font bytes, and the old conversion is not an ASCII case fold. Spaces are skipped in comparison, but also advance the target-string position; do not assume a safe eight-nonspace-character rule from that code. The shortcut can also bypass a terminator check on exactly eight matching bytes.

`func_C308A2` and `func_C308F0` call the resolver and then use separate effect-dispatch tables (`DATA8_C3455B` and `UNREACH_C3472B`). The latter substitutes `$58` when lookup returns `$FF`. Invalid-name behavior therefore needs checking for each action, not just reading.

## Current spells and proposed vocabulary

These target spell stems correspond to candidate names in the [Shiren 6 scroll reference](https://sharksnack.github.io/shiren-6/items/scrolls/). Matching each to the SFC effect is an audit inference; it does not approve importing the Shiren 6 effect. Full target names append “ Scroll.” A dash means a naming decision remains open.

| SFC effect ID | Current inventory name | Current spell | Candidate stem |
| --- | --- | --- | --- |
| `$56` | Purify Scroll | Purify | Exorcism |
| `$57` | Identify Scroll | Identify | Identifier |
| `$58` | Light Scroll | Light | Mapping |
| `$59` | Bigpot Scroll | Bigpot | Pot-upsize |
| `$5A` | Airslash Scroll | Airslash | Windblade |
| `$5B` | Lockjaw Scroll | Lockjaw | Muzzle |
| `$5C` | -- Scroll | line break | —; preserve placeholder |
| `$5D` | Trap Scroll | Trap | Trap |
| `$5E` | Crisis Scroll | Crisis | Fixer |
| `$5F` | Fastfoe Scroll | Fastfoe | Swift Foe |
| `$60` | Slumber Scroll | Slumber | Slumber |
| `$61` | Powerup Scroll | Powerup | —; retain pending decision |
| `$62` | -- Scroll | Massacre | —; preserve hidden spell |
| `$63` | Detonate Scroll | Detonate | —; do not confuse with Windblade |
| `$64` | Bigroom Scroll | Bigroom | Wall-less |
| `$65` | Monster House Scroll | Monster | Monstercall |
| `$66` | Confuse Scroll | Confuse | Confusion |
| `$67` | Genocide Scroll | Genocide | Eradication |
| `$68` | Blank Scroll | line break | Blank; do not make self-copying a new effect |
| `$69` | Lost Scroll | Lost | Map-loss |
| `$6A` | Heaven Scroll | Heaven | Heavenly |
| `$6B` | Earth Scroll | Earth | Earthly |
| `$6C` | Chrome Scroll | Chrome | Plating |
| `$6D` | Withdraw Scroll | Withdraw | Extraction |
| `$6E` | Slippery Scroll | Slippery | Carry-ban |
| `$6F` | -- Scroll | line break | —; preserve special dispatch |
| `$70` from spell lookup | New Item in normal name table | Haven | Sanctuary; validate special ground-effect paths |

`$70` here is a resolver result, not evidence that a new ordinary Sanctuary item should be created in an unused slot. `Text1228` maps to `$70` through the arithmetic above and is also tested directly by the ground-effect paths. Preserve that distinction.

Retain “Monsterh,” “Monsteho,” “Monhouse,” and “House” as aliases for `$65`. Keep “Massacre” and “Haven” compatibility even though they do not have ordinary matching inventory names. The six-character Haven checks mean merely replacing `Text1228` with the longer candidate stem would break those checks.

## Recommended changes for full new-name support

1. **Define a single resolver contract:** accepted full display name, accepted suffix-free stem, legacy aliases, explicit effect ID, and allowed actions. Generate accepted names and `Scribe:` hints from the same glossary. Keep inventory labels and numeric IDs stable.
2. **Replace positional alias assumptions with explicit mappings.** Adding aliases to the current contiguous range changes `text_id - 1202 + $56`. Keep existing text IDs in place for other consumers and put additional aliases in a separate table with explicit effect IDs. Reject empty/placeholder entries explicitly.
3. **Make matching exact after bounded normalization.** Fold ASCII letter case using the actual font encoding; define space handling and optional “Scroll” suffix removal. Accept the canonical hyphenated forms. If hyphen omission is supported, make it an explicit normalized alias and check collisions. Replace the eight-byte early success with an end-of-name comparison. A shared first eight bytes must never silently select an effect.
4. **Increase Blank Scroll input capacity to fit the approved full names.** Compute the maximum encoded length from the final glossary and legacy full-name policy, including spaces, punctuation, and termination. Do not just change `$0008` or overwrite beyond `$9367`. Trace the editor buffer, cursor, maximum-length message, copy routines, item storage, and rendering first. Keep the player-name and ordinary unidentified-item paths within their existing contracts unless separately migrated.
5. **Choose and implement persistence deliberately.** The existing per-item layout only stores eight characters. Either extend spelling storage with a proven save/load migration, or resolve at confirmation and persist a tagged stable effect plus any spelling data still needed for display/invalid-name behavior. The latter is a redesign: first trace unused storage, item copy/move/free operations, and save serialization. Do not assume spare bytes are available or sacrifice unrelated item fields. Preserve legacy eight-byte records and unknown user spellings.
6. **Route all uses through the same effect resolution.** Reading, throwing, placing/standing on Haven, displaying a written scroll, and any other call sites must agree. Replace the two six-character direct Haven checks with an effect check. Changing the visible name must not change eligibility, consumption, curse behavior, or effect dispatch.
7. **Preserve save and guide compatibility.** Accept every old valid spell and House alias; previous saves store those spellings. If normalization or alias changes reclassify an old invalid name, document the change. Verify the two extension characters survive save/load and item movement; this audit traced WRAM access, not the complete serializer.
8. **Update user-facing text together.** Replace old `Scribe:` hints, Blank Scroll instructions, and the Sabu tutorial. Show a spelling the editor can actually enter. Preserve precise SFC rules; no new “must appear in the notebook” requirement is part of this translation.

If input/save changes are deferred, an eight-character alias system is a possible interim release: choose unique short aliases, document them in `Scribe:`, and retain old aliases. It is a reduced scope, not completion of full displayed-name entry. Prefix truncation alone is not an acceptable implementation.

## Required regression matrix

| Test | Expected evidence |
| --- | --- |
| Every approved full name and stem | Resolves to its explicit SFC effect; test the action that actually activates it. |
| Old spells and House aliases | Same effects as baseline, including already-written save items. |
| Exact eight-character names; longer names | No accidental prefix success; full input is retained or an explicit input limit is shown. |
| Case, spaces, hyphens, suffix | Results match documented normalization; no inaccessible keyboard characters. |
| Similar names, partial names, extra trailing letters, empty input | No wrong effect or accidental placeholder match; compare invalid-name behavior to baseline. |
| Massacre and Haven | Hidden read effect and ground protection still work; test Haven by placement/standing, not only reading. |
| Genocide/Eradication | Throw at a monster and verify the SFC removal behavior. |
| Unknown, cursed, already-written, canceled entries | Same eligibility, turn cost, and consumption as baseline. |
| Multiple written scrolls | Distinct spellings/effects survive inventory reorder, drop/pickup, pot storage/extraction, and relevant duplication/movement paths. |
| Save/load, floor transition, warehouse, suspend/resume | Legacy and new names retain the same effects; extension bytes do not leak between item slots. |
| Fei's problems | Recheck both Blank Scroll placements in `data/maps/feis_problems/items.asm` near lines 80 and 131, including the one paired with Airslash. |
| Shared editor users | Player names and unidentified-item names still enter, save, and display correctly. |

Use a host-side resolver/encoding check for all glossary entries and collision cases, plus emulator traces of the actual ROM. A host model alone cannot prove that the 65816 registers, bank changes, buffers, and persistence paths are correct. Runtime behavior above remains untested in this audit.
