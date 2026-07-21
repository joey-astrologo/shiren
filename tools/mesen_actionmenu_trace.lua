-- mesen_actionmenu_trace.lua
-- Trace which code writes the action-menu glyphs into the WRAM staging
-- buffer ($7F:AF00-$7F:B7FF, covers the observed $7FB21E composite site).
-- USAGE: load this script FIRST (menu closed), then open the action menu
-- on a food item. Wait ~2 seconds, then copy the log pane output back.

local counts, first, order = {}, {}, {}
local total = 0
local MAXEV = 200000

local ok, err = pcall(function()
  emu.addMemoryCallback(function(addr, value)
    if total >= MAXEV then return end
    total = total + 1
    local st = emu.getState()
    local pc = string.format("%02X%04X", st.cpu.k, st.cpu.pc)
    if not counts[pc] then
      counts[pc] = 0
      first[pc] = string.format("addr=%06X val=%02X", addr, value)
      order[#order + 1] = pc
    end
    counts[pc] = counts[pc] + 1
  end, emu.callbackType.write, 0x7FAF00, 0x7FB7FF)
end)
if not ok then
  emu.log("addMemoryCallback failed: " .. tostring(err))
  return
end

emu.log("trace armed on $7FAF00-$7FB7FF - now open the action menu")

local frames = 0
emu.addEventCallback(function()
  frames = frames + 1
  if frames % 300 == 0 then
    emu.log(string.format("== summary @ frame %d (%d writes) ==", frames, total))
    for _, pc in ipairs(order) do
      emu.log(string.format("  PC %s x%d (first %s)", pc, counts[pc], first[pc]))
    end
  end
end, emu.eventType.endFrame)
