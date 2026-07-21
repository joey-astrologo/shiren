-- mesen_actionmenu_dump.lua
-- Capture everything needed to identify the stray kana glyph in the item
-- action menu (Take/Eat/Toss/Swap/Info).
-- USAGE: in-dungeon, open the inventory, cursor onto a FOOD item (grass /
-- onigiri) and press A so the action menu with "Eat" + stray character is
-- visible. THEN load this script and copy the whole log pane output back.

local function rb(addr, mt)
  return emu.read(addr, mt)
end

local function rw(addr, mt)
  local ok, v = pcall(emu.readWord, addr, mt)
  if ok and v then return v end
  return rb(addr, mt) + rb(addr + 1, mt) * 256
end

-- 1) PPU state: bg mode, tilemap/chr bases, scroll. Schema differs between
-- Mesen builds, so walk the state table defensively and log everything
-- that looks relevant.
local wanted = { "mode", "tilemap", "chr", "scroll", "layer", "screen",
                 "mosaic", "address", "size", "vram", "oam" }
local function interesting(k)
  k = string.lower(tostring(k))
  for _, w in ipairs(wanted) do
    if string.find(k, w, 1, true) then return true end
  end
  return false
end

local lines = 0
local function walk(t, prefix, depth)
  if depth > 4 or lines > 250 then return end
  for k, v in pairs(t) do
    local path = prefix == "" and tostring(k) or (prefix .. "." .. tostring(k))
    if type(v) == "table" then
      walk(v, path, depth + 1)
    elseif interesting(path) then
      emu.log(string.format("state %s = %s", path, tostring(v)))
      lines = lines + 1
    end
  end
end

emu.log("== PPU state ==")
local ok, st = pcall(emu.getState)
if ok and type(st) == "table" then
  walk(st, "", 0)
else
  emu.log("getState failed: " .. tostring(st))
end

-- 2) WRAM text compose buffer (same buffer the ranking screens used).
-- Dump a wide window: $7F:EF00-$7F:F7FF as words.
emu.log("== WRAM buffer $7FEF00-$7FF7FF (words) ==")
for base = 0x1EF00, 0x1F7E0, 0x20 do
  local parts = {}
  for off = 0, 0x1E, 2 do
    parts[#parts + 1] = string.format("%04X", rw(base + off, emu.memType.snesWorkRam))
  end
  emu.log(string.format("7F%04X: %s", base, table.concat(parts, " ")))
end

-- 3) VRAM tilemaps. We don't know the bases for this screen yet, so score
-- every 2KB-aligned page by how many words look like text cells (nonzero,
-- not a solid repeat) and dump the 3 best-scoring pages as 32x32 maps.
local vr = emu.memType.snesVideoRam
local scores = {}
for page = 0, 0x1F800, 0x800 do
  local nonzero, distinct, seen = 0, 0, {}
  for off = 0, 0x7FE, 2 do
    local w = rw(page + off, vr)
    if w ~= 0 then nonzero = nonzero + 1 end
    local t = w % 0x400
    if not seen[t] then seen[t] = true; distinct = distinct + 1 end
  end
  scores[#scores + 1] = { page = page, score = distinct, nonzero = nonzero }
end
table.sort(scores, function(a, b) return a.score > b.score end)

for i = 1, 3 do
  local p = scores[i].page
  emu.log(string.format("== VRAM page %05X (distinct=%d nonzero=%d) ==",
    p, scores[i].score, scores[i].nonzero))
  for row = 0, 31 do
    local parts = {}
    for col = 0, 31 do
      parts[#parts + 1] = string.format("%04X", rw(p + row * 64 + col * 2, vr))
    end
    emu.log(string.format("%05X: %s", p + row * 64, table.concat(parts, " ")))
  end
end

emu.log("dump complete - paste everything above back")
