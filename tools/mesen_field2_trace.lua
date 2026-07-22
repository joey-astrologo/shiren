-- mesen_field2_trace.lua
-- Trace writes to the binding "field2" array ($7E823C, entries 0-3) so we
-- can see WHO writes the item-name binding for a dropped arrow and WHAT
-- value (high byte 04 in JP vs 02 in AG is the suspected bug).
-- Also marks func_C33382 (throw resolver) entry and DisplayMessage id=22,
-- so the writes belonging to the arrow batch are easy to spot.
-- getState() returns a FLAT table: st["cpu.pc"], st["cpu.k"].
-- USAGE: load, dodge ONE arrow, paste the whole log.

local wr = emu.memType.snesWorkRam
local function pcstr()
  local st = emu.getState()
  local pc, k = st["cpu.pc"], st["cpu.k"]
  if pc then return string.format("%02X%04X", k or 0, pc) end
  return "??????"
end

-- writes to $7E823C-$7E8243 (field2 entries 0..3, 2 bytes each)
emu.addMemoryCallback(function(addr, value)
  local ent = (addr - 0x823C) // 2
  emu.log(string.format("  field2[%d] <- %02X  @PC=%s (addr %06X)", ent, value, pcstr(), addr))
end, emu.callbackType.write, 0x7E823C, 0x7E8243)

emu.addMemoryCallback(function()
  emu.log(">> func_C33382 (throw resolver) entered")
end, emu.callbackType.exec, 0xC33382, 0xC33382)

local shown = false
emu.addMemoryCallback(function()
  local id = emu.read(0x0, wr) + emu.read(0x1, wr) * 256
  if id == 22 and not shown then
    shown = true
    emu.log(">> DisplayMessage id=22 (the blank box)")
  end
end, emu.callbackType.exec, 0xC62525, 0xC62525)

emu.log("field2 trace armed - dodge ONE arrow, paste the whole log")
