-- mesen_message_trace.lua
-- Log every message ID passed to DisplayMessage ($C62525) and
-- DisplayMessage1 ($C62B7E). The message ID is a 16-bit value in
-- wTemp00 = $7E0000/$7E0001 at the moment the routine is entered.
-- USAGE: load this script, then play. Trigger the bug (let a Bowya /
-- arrow-shooter fire at you until an arrow MISSES and the blank box
-- appears). Copy the log back - the ID logged right when the blank box
-- shows is the culprit. Melee attacks will log ID 37 (hit-target miss)
-- or 38 (dodge) for comparison; a blank box will show some other ID.

local wr = emu.memType.snesWorkRam

local function msgid()
  return emu.read(0x0, wr) + emu.read(0x1, wr) * 256
end

-- known message names for quick reading in the log
local known = {
  [37] = "Text37 'X's attack missed'",
  [38] = "Text38 'Dodged X's attack'",
  [174] = "Text174 (0xAE)",
}

local seq = 0
local function hook(addr, name)
  local ok, err = pcall(function()
    emu.addMemoryCallback(function()
      seq = seq + 1
      local id = msgid()
      local note = known[id] or ""
      emu.log(string.format("#%d %s id=%d ($%04X) %s", seq, name, id, id, note))
    end, emu.callbackType.exec, addr, addr)
  end)
  if not ok then emu.log("hook failed " .. name .. ": " .. tostring(err)) end
end

hook(0xC62525, "DisplayMessage ")
hook(0xC62B7E, "DisplayMessage1")

emu.log("message trace armed - reproduce the arrow miss (blank box)")
