-- mesen_textid_trace.lua
-- Log every text ID requested through func_C4B94F (the "print text"
-- entry point), in order. This reveals which text IDs the action menu
-- uses for Take/Eat/Toss/Swap/Info.
-- USAGE: load with menu closed, open the action menu on a food item,
-- wait a moment, paste the log tail back.

local seq = {}
local ok, err = pcall(function()
  emu.addMemoryCallback(function()
    local id = emu.read(0x0, emu.memType.snesWorkRam)
        + emu.read(0x1, emu.memType.snesWorkRam) * 256
    seq[#seq + 1] = id
    emu.log(string.format("text id $%04X (%d)", id, id))
  end, emu.callbackType.exec, 0xC4B94F, 0xC4B94F)
end)
if not ok then
  emu.log("exec callback failed: " .. tostring(err))
  return
end
emu.log("text-id trace armed - open the action menu now")
