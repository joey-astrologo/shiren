# Extending Leaderboard Name Storage

This document analyzes the feasibility of extending leaderboard names from 4 characters to 6 or more.

## Current Implementation

### Storage Structure (.srm file)
- **Name storage**: 4 bytes at the start of each entry
- **Entry size**: 40 bytes (0x28)
- **Bytes 0-3**: Name characters
- **Bytes 4-39**: Other data (score, level, stats, etc.)

### Display Code (code/bank_06.asm)
The function `func_C678AE` (line 8671) handles rendering names to VRAM:
- Writes exactly 4 characters to VRAM addresses `$B36007`, `$B36008`, `$B36009`, `$B3600A`
- Calls `func_C4BF88` four times to fetch each character
- Each character write is separated with overflow checks

## Feasibility Analysis

### ✅ **Storage Extension: FEASIBLE**

The .srm file has **space available** after the 4-byte name:

```
Entry structure (40 bytes):
Offset  Current Use         Can Extend To?
------  ----------------    --------------
+0x00   Name byte 1         Name byte 1
+0x01   Name byte 2         Name byte 2  
+0x02   Name byte 3         Name byte 3
+0x03   Name byte 4         Name byte 4
+0x04   Score/data byte 1   Name byte 5 ← AVAILABLE
+0x05   Score/data byte 2   Name byte 6 ← AVAILABLE
+0x06   Score/data byte 3   Name byte 7? (needs analysis)
+0x07   Score/data byte 4   Name byte 8? (needs analysis)
...
```

**Key findings**:
- Bytes 4-5 could potentially be repurposed for 2 more characters (extending to 6 total)
- Bytes 6+ contain critical game data and should NOT be overwritten
- **CRITICAL**: You must analyze what bytes 4-5 currently store to avoid breaking save data

### ⚠️ **Display Extension: REQUIRES CODE CHANGES**

To display 6 characters, you must modify `func_C678AE` in `code/bank_06.asm`:

**Current code** (lines 8755-8795):
- Fetches and displays exactly 4 characters
- Writes to VRAM addresses `$B36007` through `$B3600A` (4 consecutive bytes)

**Required changes**:
1. Add 2 more `func_C4BF88` call blocks (for characters 5 and 6)
2. Write to `$B3600B` and `$B3600C` for the additional characters
3. Ensure VRAM has space for 6 characters in the display layout
4. Update all duplicate code blocks (there are multiple instances around lines 8755-8920)

## Recommended Approach: Extend to 6 Characters

### Step 1: Analyze Current Data at Bytes 4-5

**Action**: Check what data is stored at offset +4 and +5 in ranking entries
```bash
# Example values from current save:
# Entry "Shir": bytes 4-5 = 0x52 0x03 (unknown purpose)
# Entry "Shop": bytes 4-5 = 0xF4 0x01 (unknown purpose)
```

**Options**:
- If bytes 4-5 are **unused/padding**: Safe to use for name extension
- If bytes 4-5 are **score related**: Must relocate or compress that data
- If bytes 4-5 are **critical flags**: Cannot extend (stay at 4 chars)

### Step 2: Modify Storage Code

**Location**: Find where the game **writes** names to SRAM
- Search for code that writes to ranking entries
- Extend from 4 bytes to 6 bytes
- Update terminator logic (0xFF padding)

### Step 3: Modify Display Code  

**File**: `code/bank_06.asm`
**Function**: `func_C678AE` (line 8671)

Add two more character fetch blocks after line 8795:

```asm
; Character 5
rep #$20 ;A->16
lda.w #$EB86
sta.b wTemp02
phx
jsl.l func_C4BF88
plx
lda.b wTemp02
cmp.w #$FFFF
beq @lbl_C679B2
sep #$20 ;A->8
sta.l $B3600B,x
rep #$20 ;A->16

; Character 6
lda.w #$EB86
sta.b wTemp02
phx
jsl.l func_C4BF88
plx
lda.b wTemp02
cmp.w #$FFFF
beq @lbl_C679B2
sep #$20 ;A->8
sta.l $B3600C,x
rep #$20 ;A->16
```

**IMPORTANT**: Repeat for all code blocks (there are multiple instances)

### Step 4: Update UI/Display Layout

- Verify VRAM layout has space for 6 characters
- Check if leaderboard table columns need adjustment
- Test that 6-character names don't overflow into other UI elements

### Step 5: Update Name Input Code

- Find player name input routine
- Allow 6 characters instead of 4
- Update any name validation/truncation logic

## Alternative: Use Pointer-Based Storage

Instead of inline storage, use:
1. **Entry stores a pointer** (2 bytes) to a name table
2. **Name table** stores variable-length names (up to 16 chars)
3. Display code follows pointer to fetch full name

**Pros**: Supports full names, more flexible
**Cons**: Much more complex, higher risk of bugs, requires extensive changes

## Risks & Considerations

1. **Save compatibility**: Modified saves won't work with original game
2. **VRAM space**: Display must have room for longer names
3. **Unknown data**: Bytes 4-5 may be important (MUST VERIFY)
4. **Multiple code paths**: Must update ALL name display routines, not just one
5. **Testing required**: Extensive testing needed to avoid corruption

## Recommendation

**Start with 6 characters (2-byte extension)**:
1. First, determine what bytes 4-5 store in entries
2. If safe, proceed with code modifications
3. Test thoroughly with backup saves
4. Consider making it optional via config/setting

**Do NOT extend beyond 6** without understanding the full entry structure, as bytes 6+ likely contain critical game data.
