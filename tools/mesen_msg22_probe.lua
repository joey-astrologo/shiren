-- mesen_msg22_probe.lua
-- Diagnostic: when DisplayMessage is entered with id=22, dump every way
-- of reaching the CPU registers (callback args + emu.getState variants)
-- so we can find SP and read the caller's return address.
-- USAGE: load, dodge an arrow, paste the log.

local wr = emu.memType.snesWorkRam
local function msgid() return emu.read(0x0, wr) + emu.read(0x1, wr) * 256 end

local function dumpkeys(t, label)
  if type(t) ~= "table" then
    emu.log(string.format("  %s: not a table (%s = %s)", label, type(t), tostring(t)))
    return
  end
  local ks = {}
  for k, v in pairs(t) do ks[#ks + 1] = tostring(k) .. "(" .. type(v) .. ")" end
  table.sort(ks)
  emu.log(string.format("  %s keys: %s", label, table.concat(ks, ", ")))
end

local done = false
emu.addMemoryCallback(function(a, b, c, d)
  if msgid() ~= 22 or done then return end
  done = true
  emu.log("=== id=22 probe ===")
  emu.log(string.format("cb args: a=%s b=%s c=%s d=%s",
    type(a), type(b), type(c), type(d)))
  dumpkeys(c, "arg#3")
  if type(c) == "table" then dumpkeys(c.cpu, "arg#3.cpu") end
  local ok, st = pcall(emu.getState)
  emu.log("getState ok=" .. tostring(ok))
  if ok then
    dumpkeys(st, "getState")
    if type(st) == "table" then dumpkeys(st.cpu, "getState.cpu") end
  end
  -- try common register accessors that some Mesen builds expose
  for _, fn in ipairs({ "getRegister", "read16" }) do
    emu.log(string.format("emu.%s = %s", fn, type(emu[fn])))
  end
end, emu.callbackType.exec, 0xC62525, 0xC62525)

emu.log("msg22 probe armed - dodge an arrow (fires once)")
