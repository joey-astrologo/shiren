-- mesen_actionmenu_dump4.lua
-- v4: self-verifying capture. Takes a screenshot, dumps BG3's visible
-- tilemap page, and renders EVERY tile referenced by it (chr base $C000)
-- as pixel art. No assumptions about where the menu text sits.
-- USAGE: action menu with "Eat" + stray char visible on screen, run,
-- paste the whole log back AND note the screenshot it saved.

local vr = emu.memType.snesVideoRam
local function rb(addr) return emu.read(addr, vr) end
local function rw(addr) return rb(addr) + rb(addr + 1) * 256 end

pcall(function() emu.takeScreenshot() end)
emu.log("screenshot requested (check Mesen's Screenshots folder)")

local CHR_BASE = 0xC000
local SYM = { [0] = ".", [1] = "-", [2] = "#", [3] = "+" }

-- tilemap page 2 ($F800) - the visible half per current scroll
emu.log("== BG3 tilemap page $F800 ==")
local used, order = {}, {}
for row = 0, 31 do
  local parts = {}
  for col = 0, 31 do
    local w = rw(0xF800 + row * 64 + col * 2)
    parts[#parts + 1] = string.format("%04X", w)
    local t = w % 0x400
    if not used[t] then
      used[t] = true
      order[#order + 1] = t
    end
  end
  emu.log(string.format("%05X: %s", 0xF800 + row * 64, table.concat(parts, " ")))
end

-- render every referenced tile; 2bpp, 16 bytes/tile, one line per tile
emu.log(string.format("== %d referenced tiles (chr base $%04X) ==", #order, CHR_BASE))
table.sort(order)
for _, t in ipairs(order) do
  local rows, empty = {}, true
  for y = 0, 7 do
    local p0 = rb(CHR_BASE + t * 16 + y * 2)
    local p1 = rb(CHR_BASE + t * 16 + y * 2 + 1)
    local line = {}
    for x = 7, 0, -1 do
      local b0 = math.floor(p0 / 2 ^ x) % 2
      local b1 = math.floor(p1 / 2 ^ x) % 2
      local v = b0 + b1 * 2
      if v ~= 0 then empty = false end
      line[#line + 1] = SYM[v]
    end
    rows[#rows + 1] = table.concat(line)
  end
  if empty then
    emu.log(string.format("tile %03X: (blank)", t))
  else
    emu.log(string.format("tile %03X: %s", t, table.concat(rows, " ")))
  end
end

emu.log("dump4 complete - paste everything above back")
