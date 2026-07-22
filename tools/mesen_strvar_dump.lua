-- mesen_strvar_dump.lua
-- Capture the string-variable binding queue and message queue at two
-- moments on an arrow dodge:
--   (1) entry of func_C330DA ($C330DA) - the drop routine - logs the item
--       being dropped and the binding count at that moment.
--   (2) DisplayMessage ($C62525) with id=22 - logs the full binding queue
--       and message queue that the blank "[item] dropped" box sees.
-- Binding queue (bank $7E): write index $81A4; descriptor arrays at
-- $81BC/$823C/$82BC/$833C (indexed by the count). Message queue: count
-- $8462, ids $8466, binding-snapshots $84E6.
-- USAGE: load, dodge ONE arrow, paste the whole log.

local wr = emu.memType.snesWorkRam
local function rb(a) return emu.read(a, wr) end
local function rw(a) return rb(a) + rb(a + 1) * 256 end

-- $7E81A4 etc. live in bank $7E low RAM = workRam offset $81A4
local function rw2(off) return rb(off) + rb(off + 1) * 256 end

-- (1) drop routine entry: item arg is wTemp02 ($02), char is wTemp00 ($00)
emu.addMemoryCallback(function()
  emu.log(string.format(">> func_C330DA entry: wTemp00(char)=%02X wTemp02(item)=%02X bindIndex($81A4)=%04X",
    rb(0x0), rb(0x2), rw2(0x81A4)))
end, emu.callbackType.exec, 0xC330DA, 0xC330DA)

-- (2) the blank message
local done = false
emu.addMemoryCallback(function()
  if rw(0x0) ~= 22 or done then return end
  done = true
  emu.log(">> DisplayMessage id=22 fired")
  emu.log(string.format("  $81A4 bindIndex=%04X  $8462 msgCount=%04X", rw2(0x81A4), rw2(0x8462)))
  emu.log("  binding descriptors [idx: $81BC $823C $82BC $833C]:")
  for i = 0, 11 do
    emu.log(string.format("   [%2d] %04X %04X %04X %04X", i,
      rw2(0x81BC + i * 2), rw2(0x823C + i * 2), rw2(0x82BC + i * 2), rw2(0x833C + i * 2)))
  end
  emu.log("  message queue [i: id snap]:")
  for i = 0, 7 do
    emu.log(string.format("   [%d] id=%04X snap=%04X", i, rw2(0x8466 + i * 2), rw2(0x84E6 + i * 2)))
  end
end, emu.callbackType.exec, 0xC62525, 0xC62525)

emu.log("strvar dump armed - dodge ONE arrow, paste the whole log")
