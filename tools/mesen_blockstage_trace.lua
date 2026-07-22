-- mesen_blockstage_trace.lua
-- Catch the code that assembles the window parameter block at $7FAC7F
-- (width byte for the action menu window). Logs PC and value for every
-- write to $7FAC70-$7FAC97.
-- USAGE: load FIRST (menus closed), then open the Remove menu on the
-- equipped item. Paste the whole log back.

local function getpc(cbstate)
  local candidates = {}
  if type(cbstate) == "table" then candidates[#candidates + 1] = cbstate end
  local ok, st = pcall(emu.getState)
  if ok and type(st) == "table" then candidates[#candidates + 1] = st end
  for _, s in ipairs(candidates) do
    if type(s.cpu) == "table" and s.cpu.pc then
      return string.format("%02X%04X", s.cpu.k or 0, s.cpu.pc)
    end
    if s["cpu.pc"] then
      return string.format("%02X%04X", s["cpu.k"] or 0, s["cpu.pc"])
    end
  end
  return "??????"
end

local count = 0
local ok, err = pcall(function()
  emu.addMemoryCallback(function(addr, value, cbstate)
    if count >= 300 then return end
    count = count + 1
    local okpc, pc = pcall(getpc, cbstate)
    if not okpc then pc = "ERR" end
    emu.log(string.format("write addr=%06X val=%02X PC=%s", addr or 0, value or 0, pc))
  end, emu.callbackType.write, 0x7FAC70, 0x7FAC97)
end)
if not ok then
  emu.log("callback failed: " .. tostring(err))
  return
end
emu.log("block-stage trace armed - open the Remove menu now")
