-- mesen_actionmenu_dump3.lua
-- v3: render the action-menu window's text as readable pixel strips.
-- CHR base corrected to byte $C000 (Mesen reports word addresses).
-- Layout from v2: text is composited into sequential tiles, 0x20 tiles
-- per 8px row; the action window occupies tile offsets $19-$1C of each
-- row, first content row at tile $160 + row*0x20.
-- USAGE: same as before - menu with "Eat" + stray char visible, run,
-- paste the log back.

local vr = emu.memType.snesVideoRam
local function rb(addr) return emu.read(addr, vr) end

local CHR_BASE = 0xC000
local SYM = { [0] = ".", [1] = "-", [2] = "#", [3] = "+" }

local function tilerow(tile, y)
  local base = CHR_BASE + tile * 16 + y * 2
  local p0, p1 = rb(base), rb(base + 1)
  local line = {}
  for x = 7, 0, -1 do
    local b0 = math.floor(p0 / 2 ^ x) % 2
    local b1 = math.floor(p1 / 2 ^ x) % 2
    line[#line + 1] = SYM[b0 + b1 * 2]
  end
  return table.concat(line)
end

-- render one 16px text line made of `n` consecutive tiles starting at
-- `top` (bottom half is top+0x20)
local function renderline(label, top, n)
  emu.log(label)
  for half = 0, 1 do
    for y = 0, 7 do
      local parts = {}
      for c = 0, n - 1 do
        parts[#parts + 1] = tilerow(top + half * 0x20 + c, y)
      end
      emu.log("  " .. table.concat(parts, ""))
    end
  end
end

-- action window: 4 text lines, tile offsets $19-$1C (plus $18 and $1D in
-- case the cursor/edges land there - render 6 cells to be safe)
for line = 0, 3 do
  local top = 0x160 + line * 0x40 + 0x18
  renderline(string.format("== action window line %d (tiles %03X-%03X) ==",
    line, top, top + 5), top, 6)
end

-- big window (item list), first 2 lines for orientation
for line = 0, 1 do
  local top = 0x160 + line * 0x40 + 0x03
  renderline(string.format("== item list line %d (tiles %03X+) ==", line, top),
    top, 20)
end

emu.log("dump3 complete - paste everything above back")
