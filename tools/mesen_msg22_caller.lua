-- mesen_msg22_caller.lua  (v2)
-- When DisplayMessage ($C62525) is entered with message id=22, log the
-- caller chain by reading return addresses off the stack.
-- getState() returns a FLAT table: st["cpu.sp"], st["cpu.pc"], etc.
-- DisplayMessage's first op is php, so at entry the stack top holds the
-- jsl return address: SP+1=PCL, SP+2=PCH, SP+3=PBR (pushed PC points at
-- the last byte of the jsl; the jsl opcode is 3 bytes earlier).
-- USAGE: load, dodge an arrow, paste the log.

local wr = emu.memType.snesWorkRam
local function msgid() return emu.read(0x0, wr) + emu.read(0x1, wr) * 256 end

local done = false
emu.addMemoryCallback(function()
  if msgid() ~= 22 or done then return end
  done = true
  local st = emu.getState()
  local sp = st["cpu.sp"]
  if not sp then emu.log("no cpu.sp"); return end

  -- immediate caller from the jsl return address at SP+1..SP+3
  local pcl = emu.read(sp + 1, wr)
  local pch = emu.read(sp + 2, wr)
  local pbr = emu.read(sp + 3, wr)
  local retpc = pch * 256 + pcl
  local jsl = (retpc - 3) & 0xFFFF
  emu.log(string.format("id=22 immediate caller: jsl at $%02X%04X (returns to $%02X%04X), SP=%04X",
    pbr, jsl, pbr, (retpc + 1) & 0xFFFF, sp))

  -- dump a window of the stack so the call chain can be reconstructed;
  -- scan upward for plausible jsl return addresses (bank $C0-$C6).
  emu.log("stack window (addr: byte) and candidate return addrs:")
  for off = 1, 32 do
    local b = emu.read(sp + off, wr)
    -- try interpreting (off, off+1, off+2) as PCL,PCH,PBR
    local l = emu.read(sp + off, wr)
    local h = emu.read(sp + off + 1, wr)
    local k = emu.read(sp + off + 2, wr)
    local cand = ""
    if k >= 0xC0 and k <= 0xC6 then
      cand = string.format("  -> maybe jsl at $%02X%04X", k, (h * 256 + l - 3) & 0xFFFF)
    end
    emu.log(string.format("  [SP+%02d]=$%02X%s", off, b, cand))
  end
end, emu.callbackType.exec, 0xC62525, 0xC62525)

emu.log("msg22 caller trace v2 armed - dodge an arrow now")
