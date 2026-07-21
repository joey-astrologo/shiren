-- mesen_actionmenu_dump5.lua
-- v5: full binary dump to disk - no more selective log guessing.
-- Writes VRAM (64K), WRAM (128K), CGRAM (512), OAM (544) and a text file
-- with the PPU state to /private/tmp/shiren_dump/.
-- USAGE: action menu with "Eat" + stray char visible, run script, then
-- just tell Claude it's done (no log pasting needed).

local OUT = "/private/tmp/shiren_dump/"
os.execute('mkdir -p "' .. OUT .. '"')

local function dumpmem(mt, size, name)
  local f, err = io.open(OUT .. name, "wb")
  if not f then
    emu.log("FAILED to open " .. name .. ": " .. tostring(err))
    return
  end
  local chunk = {}
  for a = 0, size - 1 do
    chunk[#chunk + 1] = string.char(emu.read(a, mt))
    if #chunk == 4096 then
      f:write(table.concat(chunk))
      chunk = {}
    end
  end
  f:write(table.concat(chunk))
  f:close()
  emu.log("wrote " .. name .. " (" .. size .. " bytes)")
end

dumpmem(emu.memType.snesVideoRam, 0x10000, "vram.bin")
dumpmem(emu.memType.snesWorkRam, 0x20000, "wram.bin")
dumpmem(emu.memType.snesCgRam, 0x200, "cgram.bin")
dumpmem(emu.memType.snesSpriteRam, 0x220, "oam.bin")

-- PPU state as text
local f = io.open(OUT .. "state.txt", "w")
if f then
  local function walk(t, prefix)
    for k, v in pairs(t) do
      local path = prefix == "" and tostring(k) or (prefix .. "." .. tostring(k))
      if type(v) == "table" then
        walk(v, path)
      else
        f:write(path .. " = " .. tostring(v) .. "\n")
      end
    end
  end
  local ok, st = pcall(emu.getState)
  if ok and type(st) == "table" then walk(st, "") end
  f:close()
  emu.log("wrote state.txt")
end

emu.log("dump5 complete - files in " .. OUT)
