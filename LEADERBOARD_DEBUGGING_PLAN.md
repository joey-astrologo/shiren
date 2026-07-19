# Leaderboard Name Extension - Debugging Plan

Since you have emulator debugging with breakpoints and traces, we can properly implement 6-character names by systematically mapping all code paths.

## Phase 1: Map All Name Read/Write Operations

### Objective
Find EVERY place in the code that reads or writes leaderboard names.

### Memory Breakpoints to Set

#### SRAM Write Breakpoints
Set **write breakpoints** on these SRAM addresses to catch when names are written:

```
Impasse Valley entry 1:  0x6007-0x600A (name bytes)
Food God Shrine entry 1: 0x67D8-0x67DB (name bytes)
Wall Scroll Cave entry 1: 0x6FA9-0x6FAC (name bytes)
Final Problem entry 1:   0x777A-0x777D (name bytes)
```

#### VRAM Write Breakpoints
Set **write breakpoints** on VRAM where names are displayed:

```
$B36007-$B3600A (first name display location)
```

### Test Scenarios

#### Scenario 1: Create New Ranking Entry
1. Play the game and die in Impasse Valley
2. When prompted for name, enter "TEST"
3. Breakpoints will trigger when:
   - Name is written to SRAM (0x6007)
   - Name is displayed on screen ($B36007)
4. **Record the call stack** at each breakpoint

#### Scenario 2: View Existing Rankings
1. Load a save with rankings
2. View the leaderboard screen
3. Breakpoints trigger when names are read and displayed
4. **Record which functions read from SRAM**

#### Scenario 3: All Four Dungeons
Repeat Scenario 1 and 2 for each dungeon:
- Impasse Valley (0x6007)
- Food God Shrine (0x67D8)
- Wall Scroll Cave (0x6FA9)
- Final Problem (0x777A)

### Expected Findings

You should discover:
- **Write functions**: Where player name is saved to SRAM
- **Read functions**: Where names are loaded from SRAM
- **Display functions**: Where names are rendered to VRAM (we know `func_C678AE` is one)
- **Sort/compare functions**: How rankings are ordered
- **Initialization functions**: Where default names are set

### Data to Collect

For each breakpoint hit, record:
1. **PC (Program Counter)**: Where in ROM the code is
2. **Call stack**: How we got there
3. **Register values**: A, X, Y registers
4. **RAM values**: Relevant working memory ($00-$FF)

## Phase 2: Analyze Name Input Routine

### Objective
Understand how player names are entered and where the 4-character limit is enforced.

### Breakpoints

Set breakpoint on name entry screen code. Find it by:
1. Start a new game or die
2. When name entry screen appears, pause emulator
3. Search for code accessing the name being typed

### Questions to Answer

1. Where is the "4 character max" enforced?
2. What happens when you press the confirmation button?
3. Where does it write the name to SRAM?
4. Can we trace from input → SRAM write?

## Phase 3: Trace Score Storage

### Objective
Confirm score is at offset +4/+5 and find where it's written/read.

### Breakpoints

```
Impasse Valley entry 1 score: 0x600B-0x600C (bytes 4-5)
```

### Test
1. Die in game with different scores
2. Verify score is written to offset +4/+5
3. Find the write function
4. **This is the function we need to modify** to relocate score

## Phase 4: Create Minimal Test Patch

### Step 1: Relocate Score (Proof of Concept)

**Goal**: Move score from bytes 4-5 to bytes 36-37

```asm
; Find the score write function (from Phase 3)
; Current code writes to: entry_address + 4
; Change to write to: entry_address + 36

; Example (addresses will vary):
; OLD:
sta.l $B36004,x  ; Write score low byte at +4
sta.l $B36005,x  ; Write score high byte at +5

; NEW:
sta.l $B36024,x  ; Write score low byte at +36
sta.l $B36025,x  ; Write score high byte at +37
```

**Update score read code similarly**

### Step 2: Extend Name Write (Proof of Concept)

**Goal**: Write 6 characters instead of 4

Find the name write function (from Phase 1) and extend it:

```asm
; Current: Writes 4 bytes at entry_address + 0
; New: Write 6 bytes at entry_address + 0

; If current code is a loop, change loop counter from 4 to 6
; If it's manual writes, add 2 more character writes
```

### Step 3: Extend Display Code

**Goal**: Display 6 characters instead of 4

Modify `func_C678AE` (line 8671 in bank_06.asm) to add 2 more character fetches:

```asm
; After the existing 4 character writes (line 8794)
; Add character 5:
rep #$20
lda.w #$EB86
sta.b wTemp02
phx
jsl.l func_C4BF88
plx
lda.b wTemp02
cmp.w #$FFFF
beq @done
sep #$20
sta.l $B3600B,x   ; Character 5
rep #$20

; Add character 6:
lda.w #$EB86
sta.b wTemp02
phx
jsl.l func_C4BF88
plx
lda.b wTemp02
cmp.w #$FFFF
beq @done
sep #$20
sta.l $B3600C,x   ; Character 6
rep #$20

@done:
; ... existing code continues
```

### Step 4: Test Single Dungeon

1. Apply patches for Impasse Valley ONLY
2. Test:
   - Enter 6-character name
   - Verify it saves to SRAM correctly
   - Verify it displays on screen
   - Verify score still works
   - Verify sorting still works

## Phase 5: Extend to All Dungeons

Once Impasse Valley works:

### Find Other Display Functions

From Phase 1, you should have found display functions for:
- Food God Shrine
- Wall Scroll Cave
- Final Problem

### Apply Same Pattern

For each dungeon's display function:
1. Add 2 more character fetch blocks (same as Step 3 above)
2. Ensure VRAM addresses are correct
3. Test each dungeon independently

## Phase 6: Update Name Input

### Extend Input to 6 Characters

From Phase 2, modify name entry code:
1. Change max length from 4 to 6
2. Adjust cursor limits
3. Adjust display width if needed

## Testing Checklist

After all patches applied, verify:

- [ ] Can enter 6-character names in name entry screen
- [ ] Names save correctly to SRAM (all 6 chars)
- [ ] Names display correctly in rankings (all 6 chars)
- [ ] All 4 dungeons work (Impasse Valley, Food God, Wall Scroll, Final Problem)
- [ ] Scores still display correctly
- [ ] Ranking order (sorting) still works
- [ ] Default names still work
- [ ] No graphical glitches (names don't overflow into other columns)
- [ ] Save/load preserves names correctly
- [ ] Multiple playthroughs accumulate correctly

## Debugging Tools Needed

### 1. SRAM Monitor Script

Create a script to watch SRAM changes in real-time:

```python
# Monitor specific SRAM addresses during gameplay
# Display name bytes and score bytes for entry 1 of each dungeon
```

### 2. VRAM Viewer

Use emulator's VRAM viewer to verify:
- Names are being written to correct VRAM locations
- No overflow into adjacent display areas
- All 6 characters visible

### 3. Trace Logger

Enable trace logging for:
- All memory writes to 0x6000-0x8000 (SRAM region)
- Function calls to identified name-related functions

## Risk Mitigation

1. **Keep backups** of original ROM and saves
2. **Test one dungeon at a time** before applying to all
3. **Verify score relocation** doesn't break anything
4. **Check for hardcoded offsets** in other code that might reference bytes 4-5
5. **Test edge cases**: empty names, full rankings (50 entries), etc.

## Expected Timeline

With debugging tools:
- Phase 1 (Mapping): 2-4 hours
- Phase 2 (Name Input): 1-2 hours
- Phase 3 (Score Trace): 1 hour
- Phase 4 (Proof of Concept): 2-3 hours
- Phase 5 (All Dungeons): 2-3 hours
- Phase 6 (Name Input Patch): 1-2 hours
- Testing: 2-4 hours

**Total: ~12-20 hours of focused debugging work**

## Success Criteria

You'll know it's working when:
1. You can enter "Shiren" (6 chars) as player name
2. It appears in rankings showing all 6 characters
3. Works in all 4 dungeons
4. Scores and sorting remain functional
5. No crashes or corruption

## Next Steps

Start with **Phase 1** and collect the data. Once you have:
- List of all functions that read/write names
- SRAM write addresses confirmed
- VRAM display addresses confirmed

We can create precise patches for each function.

Would you like me to create helper scripts for the debugging process?
