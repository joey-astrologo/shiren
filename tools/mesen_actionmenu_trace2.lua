-- mesen_actionmenu_trace2.lua
-- v2: PC lookup made robust - tries the callback's state argument, then
-- emu.getState() variants; logs the available schema once if all fail.
-- USAGE: load with menu closed, open the action menu on a food item,
-- wait a few seconds, paste the latest summary block back.

local counts, first, order = {}, {}, {}
local total = 0
local diagnosed = false

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
    if s.pc then
      return string.format("%02X%04X", s.k or 0, s.pc)
    end
  end
  if not diagnosed then
    diagnosed = true
    for _, s in ipairs(candidates) do
      local keys = {}
      for k in pairs(s) do keys[#keys + 1] = tostring(k) end
      table.sort(keys)
      emu.log("state keys: " .. table.concat(keys, ", "))
    end
    if #candidates == 0 then emu.log("no state available in callback") end
  end
  return "??????"
end

local ok, err = pcall(function()
  emu.addMemoryCallback(function(addr, value, cbstate)
    if total >= 200000 then return end
    total = total + 1
    local okpc, pc = pcall(getpc, cbstate)
    if not okpc then pc = "ERR" end
    if not counts[pc] then
      counts[pc] = 0
      first[pc] = string.format("addr=%06X val=%02X", addr or 0, value or 0)
      order[#order + 1] = pc
    end
    counts[pc] = counts[pc] + 1
  end, emu.callbackType.write, 0x7FAF00, 0x7FB7FF)
end)
if not ok then
  emu.log("addMemoryCallback failed: " .. tostring(err))
  return
end

emu.log("trace2 armed on $7FAF00-$7FB7FF - open the action menu now")

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
