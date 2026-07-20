-- mesen_seal_stress.lua (v4)
-- Empirically confirm the seal-list clamp: when the seal-count routine
-- at $C49E2B runs, its flags word sits in DP $00 - poke it to the full
-- 12-seal shield mask $76FD and watch what the popup does. The routine
-- clamps the count at 9 (cpy #$000A / bcc / ldy #$0009), so the window
-- should show 9 attribute lines, cleanly.
-- USAGE: run the script, open the sealed shield's description.

emu.addMemoryCallback(function()
  local st = emu.getState()
  local d = st["cpu.d"] or (st.cpu and st.cpu.d) or 0
  emu.write(d + 0, 0xFD, emu.memType.snesWorkRam)
  emu.write(d + 1, 0x76, emu.memType.snesWorkRam)
  emu.log(string.format("poked flags at DP=%04X to $76FD (12 seals)", d))
end, emu.callbackType.exec, 0xC49E2B, 0xC49E2B, emu.cpuType.snes, emu.memType.snesMemory)

emu.log("12-seal poke armed: open the sealed shield's description now")
