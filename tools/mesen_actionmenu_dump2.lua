-- mesen_actionmenu_dump2.lua
-- v2: BG3's visible tilemap page ($F800, rows 32-63 of the double-height
-- map) plus decoded 2bpp pixels for every distinct non-blank tile in it,
-- so the stray kana can be identified visually.
-- USAGE: same as v1 - action menu with "Eat" + stray char on screen,
-- run script, paste the whole log back.

local vr = emu.memType.snesVideoRam

local function rb(addr) return emu.read(addr, vr) end
local function rw(addr)
  local ok, v = pcall(emu.readWord, addr, vr)
  if ok and v then return v end
  return rb(addr) + rb(addr + 1) * 256
end

local CHR_BASE = 0x6000   -- layers[2].chrAddress from v1 dump (bytes)
local BLANK = 0x2A0

-- 1) tilemap page 2 ($F800): rows 32-63
emu.log("== BG3 tilemap page $F800 (rows 32-63) ==")
local used, order = {}, {}
for row = 0, 31 do
  local parts = {}
  for col = 0, 31 do
    local w = rw(0xF800 + row * 64 + col * 2)
    parts[#parts + 1] = string.format("%04X", w)
    local t = w % 0x400
    if t ~= BLANK and not used[t] then
      used[t] = true
      order[#order + 1] = t
    end
  end
  emu.log(string.format("%05X: %s", 0xF800 + row * 64, table.concat(parts, " ")))
end

-- 2) decode each distinct tile as 8x8 ascii (2bpp: 16 bytes/tile,
-- rows are plane0/plane1 byte pairs)
emu.log(string.format("== %d distinct tiles (chr base $%04X, 2bpp) ==", #order, CHR_BASE))
local MAXT = 120
for i = 1, math.min(#order, MAXT) do
  local t = order[i]
  local base = CHR_BASE + t * 16
  local rows = {}
  for y = 0, 7 do
    local p0 = rb(base + y * 2)
    local p1 = rb(base + y * 2 + 1)
    local line = {}
    for x = 7, 0, -1 do
      local bit0 = math.floor(p0 / 2 ^ x) % 2
      local bit1 = math.floor(p1 / 2 ^ x) % 2
      local v = bit0 + bit1 * 2
      line[#line + 1] = (v == 0) and "." or tostring(v)
    end
    rows[#rows + 1] = table.concat(line)
  end
  emu.log(string.format("tile %03X: %s", t, table.concat(rows, " ")))
end
if #order > MAXT then
  emu.log(string.format("(%d more tiles omitted)", #order - MAXT))
end

emu.log("dump2 complete - paste everything above back")
