-- mesen_tilemap_dump.lua
-- Dump the ranking detail screen's text tilemap buffer and the palette RAM
-- so we can see exactly which palette the equipment-line cells use.
-- USAGE: bring up the detail screen (the one with Weapon/Shield lines),
-- THEN load and run this script; copy the whole log pane output back.

local function rw(addr, mt)
  local ok, v = pcall(emu.readWord, addr, mt)
  if ok and v then return v end
  return emu.read(addr, mt) + emu.read(addr + 1, mt) * 256
end

-- text tilemap buffer in WRAM: $7F:F4C0-$7FF7FF (covers the equipment
-- rows incl. the star cells at $7FF554/$7FF5D4 and bottom rows)
emu.log("== WRAM tilemap buffer $7FF4C0-$7FF7FF (words) ==")
for base = 0x1F4C0, 0x1F7E0, 0x20 do
  local parts = {}
  for off = 0, 0x1E, 2 do
    parts[#parts + 1] = string.format("%04X", rw(base + off, emu.memType.snesWorkRam))
  end
  emu.log(string.format("7F%04X: %s", base, table.concat(parts, " ")))
end

-- CGRAM: 128 BG colors (palettes 0-7, 16 colors each)
emu.log("== CGRAM colors 0-127 (BGR555 words) ==")
for pal = 0, 7 do
  local parts = {}
  for c = 0, 15 do
    parts[#parts + 1] = string.format("%04X", rw((pal * 16 + c) * 2, emu.memType.snesCgRam))
  end
  emu.log(string.format("pal%d: %s", pal, table.concat(parts, " ")))
end

-- allocator state for reference
emu.log(string.format("alloc: 7ED670=%04X 7ED674=%04X",
  rw(0x1D670, emu.memType.snesWorkRam), rw(0x1D674, emu.memType.snesWorkRam)))
emu.log("dump complete - paste everything above back")
