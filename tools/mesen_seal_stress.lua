-- mesen_seal_stress.lua
-- Stress-test the item-description seal list: when the seal renderer
-- (bank_04 $C4224A region) starts, poke the inspected item's seal flags
-- word ($7EA9CE/CF) to the full shield mask $76FD = 12 seals, so the
-- popup has to render the maximum number of attribute lines.
-- USAGE: run the script, then open any sealed shield's description from
-- the inventory. Purely in-RAM: nothing touches the save file.

local armed = true

emu.addMemoryCallback(function()
  if armed then
    emu.write(0xA9CE, 0xFD, emu.memType.snesWorkRam)
    emu.write(0xA9CF, 0x76, emu.memType.snesWorkRam)
    emu.log("seal flags poked to $76FD (12 seals) for this description")
  end
end, emu.callbackType.exec, 0xC4224A, 0xC4224A, emu.cpuType.snes, emu.memType.snesMemory)

emu.log("seal stress armed: open a sealed shield's description now")
