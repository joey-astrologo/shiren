-- mesen_windowwidth_trace.lua
-- Catch the code that sets a window's width, and the ROM parameter block
-- it reads from. Watches writes to the width-in-tiles table ($7FDE5E+)
-- and the pixel-limit table ($7FDECA+). On each write it also logs the
-- 24-bit pointer at DP $00-$02 (wTemp00) - during window creation that
-- is the address of the ROM parameter block whose byte 0 is the width.
-- USAGE: load this FIRST (menus closed), then open the inventory and
-- press A on the EQUIPPED weapon/shield so the Remove menu opens.
-- Paste the whole log back.

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

local wr = emu.memType.snesWorkRam
local function blockptr()
  local lo = emu.read(0x0, wr)
  local mid = emu.read(0x1, wr)
  local hi = emu.read(0x2, wr)
  return string.format("%02X%02X%02X", hi, mid, lo)
end

local count = 0
local function watch(startAddr, endAddr, label)
  local ok, err = pcall(function()
    emu.addMemoryCallback(function(addr, value, cbstate)
      if count >= 400 then return end
      count = count + 1
      local okpc, pc = pcall(getpc, cbstate)
      if not okpc then pc = "ERR" end
      local okbp, bp = pcall(blockptr)
      if not okbp then bp = "ERR" end
      emu.log(string.format("%s write addr=%06X val=%02X PC=%s wTemp00ptr=$%s",
        label, addr or 0, value or 0, pc, bp))
    end, emu.callbackType.write, startAddr, endAddr)
  end)
  if not ok then
    emu.log("callback failed for " .. label .. ": " .. tostring(err))
  end
end

-- width in tiles, 6 slots x 2 bytes
watch(0x7FDE5E, 0x7FDE69, "DE5E(tiles)")
-- width limit in pixels, 6 slots x 2 bytes
watch(0x7FDECA, 0x7FDED5, "DECA(px)")

emu.log("window-width trace armed - now open the Remove menu")
