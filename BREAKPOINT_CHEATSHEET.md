# Debugger Breakpoint Cheatsheet

Quick reference for setting up debugging sessions to trace leaderboard code.

## Memory Regions

### SRAM (Save RAM)
```
Bank: $B3 (SNES addressing: $B3:6000-$B3:7FFF)
      or $30 in some contexts
```

### VRAM (Video RAM - Display)
```
PPU registers write to VRAM
Watch for writes to $B36007-$B3600C for name display
```

## Critical Breakpoints

### Phase 1: Find Name Write Functions

#### SRAM Write Breakpoints (Set ALL of these)
```
Break on WRITE to:
  Impasse Valley:
    $B3:6007 (entry 1, char 1)
    $B3:6008 (entry 1, char 2)
    $B3:6009 (entry 1, char 3)
    $B3:600A (entry 1, char 4)

  Food God Shrine:
    $B3:67D8 (entry 1, char 1)
    $B3:67D9 (entry 1, char 2)
    $B3:67DA (entry 1, char 3)
    $B3:67DB (entry 1, char 4)

  Wall Scroll Cave:
    $B3:6FA9 (entry 1, char 1)
    $B3:6FAA (entry 1, char 2)
    $B3:6FAB (entry 1, char 3)
    $B3:6FAC (entry 1, char 4)

  Final Problem:
    $B3:777A (entry 1, char 1)
    $B3:777B (entry 1, char 2)
    $B3:777C (entry 1, char 3)
    $B3:777D (entry 1, char 4)
```

#### Score Write Breakpoints
```
Break on WRITE to:
  Impasse Valley entry 1 score:
    $B3:600B (score low byte)
    $B3:600C (score high byte)
```

### Phase 2: Find Display Functions

#### Known Display Function
```
Break on EXECUTE:
  $C6:78AE (func_C678AE - confirmed display function)
```

#### VRAM Write Breakpoints
```
Break on WRITE to:
  $B3:6007 through $B3:600A (first 4 display chars)
  $B3:600B through $B3:600C (if extending to 6 chars)
```

### Phase 3: Find Name Input

#### Test by pausing on name entry screen
```
1. Get to name entry screen
2. Pause emulator
3. Search RAM for the partial name you've typed
4. Set read/write breakpoints on those addresses
5. Continue typing and see what code accesses them
```

## Emulator-Specific Commands

### bsnes-plus / Mesen-S
```
# Memory breakpoints
break $B36007 write     # Break on write to address
break $B36007 read      # Break on read from address
break $C678AE exec      # Break on executing code at address

# Conditional breakpoints
break $B36007 write if A == #$26  # Only if A register = 0x26 ('S')

# Trace logging
trace on                # Enable instruction trace
trace memory            # Log all memory access
```

### no$sns
```
[b36007]   ; Write breakpoint
[c678ae]   ; Execute breakpoint
```

### Mednafen
```
# In debugger prompt:
break write 0xB36007
break exec 0xC678AE
trace
```

## What to Record

When breakpoint hits, record:

### 1. Register Dump
```
A:  ____  (Accumulator)
X:  ____  (X index)
Y:  ____  (Y index)
DB: ____  (Data Bank)
PC: ____  (Program Counter)
SP: ____  (Stack Pointer)
P:  ____  (Processor Status)
```

### 2. Call Stack
```
Most emulators show call stack automatically.
Record the last 3-5 function calls.
Example:
  $C6:78AE (current)
  <- $C6:6540
  <- $C6:3210
```

### 3. Memory Context
```
Look at nearby memory:
- What's at the address being accessed?
- What's in work RAM ($00-$FF)?
- Related addresses nearby?
```

### 4. Code Context
```
Disassemble 10-20 instructions around PC
Save the assembly listing
Note any loops, comparisons, or branches
```

## Test Scenarios

### Scenario A: Player Dies in Impasse Valley
```
1. Set ALL Impasse Valley write breakpoints
2. Play game, die with specific score (e.g., 1000)
3. Enter name "TEST"
4. When breakpoint hits:
   - Record PC (where in ROM)
   - Record call stack
   - Record A register (should be character being written)
   - Record X register (likely offset into table)
5. Continue, hit next breakpoint
6. Repeat for all 4 characters
```

**Expected Result**: Find the function that writes player name to SRAM

### Scenario B: View Rankings
```
1. Set Impasse Valley read breakpoints
2. Load save with existing rankings
3. Navigate to rankings screen
4. When breakpoint hits:
   - Record which function is reading
   - Record destination (where it's copying to)
```

**Expected Result**: Find the function(s) that read names for display

### Scenario C: All Dungeons
```
Repeat Scenario A for:
- Food God Shrine (die there)
- Wall Scroll Cave (die there)
- Final Problem (die there)
```

**Expected Result**: Discover if all dungeons use same code or different functions

## Quick Debug Session Template

```
=== DEBUG SESSION: [Date/Time] ===
Objective: Find name write function for Impasse Valley
ROM Version: [version]
Emulator: [name + version]

Breakpoints Set:
- $B3:6007 write ✓
- $B3:6008 write ✓
- $B3:6009 write ✓
- $B3:600A write ✓

Test Action: Died in Impasse Valley, entered name "TEST"

BREAKPOINT 1: $B3:6007 write
  PC: $______
  A: $__ (char being written)
  X: $____
  Y: $____
  Call Stack:
    - $______
    - $______
  Notes: [what you observed]

BREAKPOINT 2: $B3:6008 write
  [repeat above]

Findings:
- Function at $______ writes names
- Uses [loop/manual writes]
- X register holds [offset/index/etc]

Next Steps:
- [what to investigate next]
```

## Common Issues & Solutions

### Issue: Breakpoint Never Hits
**Possible causes:**
- Wrong address (check SRAM mapping)
- Wrong bank ($B3 vs $30 vs $7E)
- Game uses different storage location
- Action doesn't trigger that code path

**Solution:**
- Use SRAM monitor script to find actual write location
- Try different bank numbers
- Check if emulator supports that breakpoint type

### Issue: Too Many Breakpoint Hits
**Possible causes:**
- Address is used for other purposes
- Multiple code paths access same location

**Solution:**
- Use conditional breakpoints (only if A == specific value)
- Record ALL hits, analyze patterns
- Narrow down to specific test case

### Issue: Can't Find Display Function
**Possible causes:**
- Name is copied to WRAM first, then to VRAM
- DMA transfer instead of direct write
- Graphics rendering uses indirect method

**Solution:**
- Break on known function $C6:78AE first
- Trace backwards from display to find source
- Watch for DMA setup code

## Data Collection Goals

By end of Phase 1, you should have:
- [ ] List of ROM addresses that WRITE names to SRAM
- [ ] List of ROM addresses that READ names from SRAM
- [ ] List of ROM addresses that DISPLAY names to screen
- [ ] Confirmation that all 4 dungeons use same/different code
- [ ] Understanding of name storage format in SRAM

With this data, we can create precise assembly patches.
