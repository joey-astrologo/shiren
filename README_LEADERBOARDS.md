# Shiren SFC Leaderboard Documentation

Complete documentation and tools for understanding and modifying the leaderboard system.

## Quick Links

- **[LEADERBOARD_SRM_FORMAT.md](LEADERBOARD_SRM_FORMAT.md)** - SRAM structure reference
- **[EXTENDING_LEADERBOARD_NAMES.md](EXTENDING_LEADERBOARD_NAMES.md)** - Analysis of name extension feasibility
- **[LEADERBOARD_DEBUGGING_PLAN.md](LEADERBOARD_DEBUGGING_PLAN.md)** - Step-by-step debugging guide
- **[BREAKPOINT_CHEATSHEET.md](BREAKPOINT_CHEATSHEET.md)** - Debugger reference

## Tools

### Analysis Tools

#### `tools/parse_srm_leaderboard.py`
Parse and display all leaderboard names from a .srm save file.

```bash
python3 tools/parse_srm_leaderboard.py shiren-aeon-genesis.srm
```

**Output:**
- All 4 leaderboards (Impasse Valley, Food God Shrine, Wall Scroll Cave, Final Problem)
- Up to 50 entries per leaderboard
- Only shows non-empty entries

#### `tools/analyze_ranking_structure.py`
Deep analysis of ranking entry structure to understand data layout.

```bash
python3 tools/analyze_ranking_structure.py shiren-aeon-genesis.srm
```

**Output:**
- Full 40-byte structure of each entry
- Identifies name bytes, score bytes, and other data
- Helps determine safe locations for data relocation

### Debugging Tools

#### `tools/monitor_sram_changes.py`
Compare SRAM before/after gameplay to see what changed.

```bash
# Before gameplay action
cp save.srm save_before.srm

# After gameplay (die, view rankings, etc.)
cp save.srm save_after.srm

# See what changed
python3 tools/monitor_sram_changes.py save_before.srm save_after.srm
```

**Use cases:**
- Identify which SRAM addresses are written during leaderboard updates
- Confirm score storage location
- Find other data associated with rankings

#### `tools/inject_test_name.py`
Inject custom names into SRAM for testing display without playing.

```bash
# Inject "Shiren" (6 chars) into Impasse Valley entry 1
python3 tools/inject_test_name.py save.srm test.srm "Shiren" impasse 1
```

**Use cases:**
- Test if modified display code handles 6+ character names
- Verify VRAM rendering without gameplay
- Quick iteration on display modifications

## Current Understanding

### SRAM Structure (Confirmed)

Each leaderboard supports **up to 50 entries**, spaced **40 bytes (0x28)** apart:

| Leaderboard       | Start Offset | Entry Spacing | Default Entries |
|-------------------|--------------|---------------|-----------------|
| Impasse Valley    | 0x6007       | 0x28 (40)     | 15              |
| Food God Shrine   | 0x67D8       | 0x28 (40)     | 1               |
| Wall Scroll Cave  | 0x6FA9       | 0x28 (40)     | 5               |
| Final Problem     | 0x777A       | 0x28 (40)     | 1               |

### Entry Structure (40 bytes)

```
Offset  Size  Purpose              Notes
------  ----  -------------------  ---------------------------
+0x00   4     Name                 Currently 4 characters max
+0x04   2     Score                16-bit little-endian
+0x06   34    Other data           Level, stats, etc. (TBD)
```

**Key Finding**: Bytes 4-5 store the **score**, which must be relocated to extend names to 6 characters.

### Display Code (Confirmed)

**Function**: `func_C678AE` at line 8671 in `code/bank_06.asm`

Currently:
- Calls `func_C4BF88` **four times** to fetch 4 characters
- Writes to VRAM addresses `$B36007` through `$B3600A`
- Has conditional checks for 0xFFFF (terminator)

To extend to 6 characters, need to:
- Add **two more** fetch+write blocks
- Write to `$B3600B` and `$B3600C`
- Update **all instances** (multiple code blocks exist)

## Extension Status

### What We Know ✓
- ✓ SRAM structure fully mapped
- ✓ Entry size and spacing confirmed (40 bytes)
- ✓ Name storage location identified (offset +0)
- ✓ Score storage identified (offset +4-5)
- ✓ Display function identified (`func_C678AE`)
- ✓ All 4 leaderboards mapped

### What Needs Investigation
- ⚠ Name **write** functions (where player name is saved)
- ⚠ Name **input** code (how names are entered)
- ⚠ Sorting/comparison code (how rankings are ordered)
- ⚠ Other display functions (beyond `func_C678AE`)
- ⚠ What bytes +6 through +39 contain (full entry structure)

### Extension Plan

**Goal**: Extend from 4 to 6 characters

**Requirements**:
1. Relocate score from bytes 4-5 to bytes 36-37 (or other safe location)
2. Use bytes 4-5 for characters 5-6
3. Modify all read/write/display code to handle 6 bytes instead of 4
4. Update name input to allow 6 characters
5. Verify VRAM layout has space for 6 characters

**Recommended Approach**: Follow `LEADERBOARD_DEBUGGING_PLAN.md` using emulator debugging

## Previous Attempts

### `leaderboard-fixes` Branch
**Approach**: Moved names to separate ROM table, copy 16 bytes (8 chars) to VRAM

**Issues**:
- Only works for Impasse Valley
- Doesn't save player names properly (ROM is read-only)
- Incomplete - other dungeons not updated
- Breaks SRAM format compatibility

**Lesson**: Partial implementations create more problems. Need to map **all** code paths first.

## Next Steps for Implementation

If you want to extend names to 6 characters:

1. **Phase 1: Debug Session** (2-4 hours)
   - Use `BREAKPOINT_CHEATSHEET.md` to set up emulator
   - Find all name read/write functions
   - Confirm data layout with `monitor_sram_changes.py`

2. **Phase 2: Score Relocation** (1-2 hours)
   - Create patch to move score from offset +4-5 to +36-37
   - Test on single dungeon first
   - Verify sorting still works

3. **Phase 3: Extend Display** (2-3 hours)
   - Modify `func_C678AE` to display 6 chars
   - Find and update other display functions
   - Test all 4 dungeons

4. **Phase 4: Extend Input** (1-2 hours)
   - Find name entry code
   - Change max length from 4 to 6
   - Update write functions

5. **Phase 5: Testing** (2-4 hours)
   - Test all 4 dungeons
   - Verify save/load
   - Check edge cases

**Total estimated time**: 10-20 hours with debugging tools

## Alternative: Stay at 4 Characters

**Pros**:
- Current system works
- No risk of breakage
- 4 chars sufficient for identification ("Shir", "Shop", etc.)

**Cons**:
- Can't display full player names
- Max player name is 6 chars, truncated to 4 in rankings

## Questions?

All the groundwork is laid:
- SRAM structure documented
- Analysis tools created
- Debugging plan written
- Test tools available

The path forward is clear, but requires hands-on debugging work with an emulator.

Ready to proceed when you are!
