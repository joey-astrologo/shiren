-- mesen_equipline_trace.lua
-- Instrument the ranking detail screen's equipment-line rendering so we can
-- see the REAL values and parameters instead of guessing from pixels.
-- Load in Mesen 2: Debug > Script Window > open > Run, then open the
-- leaderboard, click a row with an upgraded weapon/shield, and copy the
-- log pane output.

local function r(addr)  -- read a byte from the SNES memory space
  return emu.read(addr, emu.memType.snesMemory)
end

local function hex(v) return string.format("%02X", v) end

-- entry staging: weapon id/flags/plus at $7ED637-639, shield at $7ED63C-63E
local function dumpEntry(tag)
  emu.log(string.format(
    "%s wpn id=%s flags=%s plus=%s | shl id=%s flags=%s plus=%s",
    tag, hex(r(0x7ED637)), hex(r(0x7ED639)), hex(r(0x7ED638)),
    hex(r(0x7ED63C)), hex(r(0x7ED63E)), hex(r(0x7ED63D))))
end

-- weapon +N blob entry ($C66921) and shield +N blob entry ($C66A4E)
emu.addMemoryCallback(function()
  dumpEntry("WPN+N blob:")
end, emu.callbackType.exec, 0xC66921, 0xC66921, emu.cpuType.snes, emu.memType.snesMemory)

emu.addMemoryCallback(function()
  dumpEntry("SHL+N blob:")
end, emu.callbackType.exec, 0xC66A4E, 0xC66A4E, emu.cpuType.snes, emu.memType.snesMemory)

-- number renderer entry: log its parameter block
emu.addMemoryCallback(function()
  local st = emu.getState()
  local d = st["cpu.d"] or 0
  local parms = {}
  for i = 0, 7 do parms[#parms+1] = hex(r(d + i)) end
  emu.log(string.format(
    "C67F1F: DP=%04X parms(00-07)=%s  65D=%s%s 660=%s%s 662=%s 663=%s 65F=%s",
    d, table.concat(parms, " "),
    hex(r(0x7ED65E)), hex(r(0x7ED65D)),
    hex(r(0x7ED661)), hex(r(0x7ED660)),
    hex(r(0x7ED662)), hex(r(0x7ED663)), hex(r(0x7ED65F))))
end, emu.callbackType.exec, 0xC67F1F, 0xC67F1F, emu.cpuType.snes, emu.memType.snesMemory)

emu.log("equip-line trace armed: open a ranking detail screen now")
