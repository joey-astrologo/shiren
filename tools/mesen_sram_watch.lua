-- mesen_sram_watch.lua  (v2)
-- Mesen 2 script: prove whether SRAM banks $B1/$B2 ($6000-$7B57 regions) are
-- ever touched by the game.
--
-- HOW TO RUN: Debug > Script Window > open this file > press Run (F5).
-- ALL OUTPUT APPEARS IN THE LOG PANE AT THE BOTTOM OF THE SCRIPT WINDOW.
-- You should immediately see "watching ..." lines there; if not, the script
-- isn't running (errors also show in that pane).
--
-- What you'll see while playing:
--   CANARY lines whenever the game saves (writes to bank B0's save block).
--     These are EXPECTED and prove the watch machinery works.
--   WRITE lines if the game touches the suspect B1/B2 regions.
--     Silence on these while CANARY fires = the regions are free to claim.
--
-- On startup this script also fills the suspect regions with 0xFF (they only
-- contain Mesen's random power-on noise), so afterwards the .srm file itself
-- is evidence: any non-FF byte in those regions was written by the game.
--
-- Save-RAM file offsets: $B0 -> 0x0000, $B1 -> 0x2000, $B2 -> 0x4000, $B3 -> 0x6000

local seen = {}
local hits = 0

local function getPC()
  local ok, st = pcall(emu.getState)
  if not ok or st == nil then return "?" end
  local k = st["cpu.k"] or (st.cpu and st.cpu.k)
  local pc = st["cpu.pc"] or (st.cpu and st.cpu.pc)
  if k and pc then return string.format("%02X%04X", k, pc) end
  return "?"
end

local function onSuspectWrite(address, value)
  hits = hits + 1
  local pc = getPC()
  if not seen[pc] then
    seen[pc] = true
    emu.log(string.format("WRITE srm+%05X val=%02X from PC=%s (hit #%d)  <-- game uses B1/B2!",
      address, value, pc, hits))
  end
end

local canarySeen = {}
local function onCanaryWrite(address, value)
  local pc = getPC()
  if not canarySeen[pc] then
    canarySeen[pc] = true
    emu.log(string.format("CANARY save-block write srm+%05X from PC=%s (expected, watch works)",
      address, pc))
  end
end

-- fill suspect regions with FF so the .srm becomes file-level evidence
local filled = 0
for _, base in ipairs({0x2000, 0x4000}) do
  for a = base, base + 0x1B57 do
    local ok = pcall(emu.write, a, 0xFF, emu.memType.snesSaveRam)
    if not ok then emu.log("emu.write failed at srm+"..a) break end
    filled = filled + 1
  end
end
emu.log(string.format("filled %d suspect bytes with FF (clears power-on noise)", filled))

emu.addMemoryCallback(onSuspectWrite, emu.callbackType.write, 0x2000, 0x3B57,
  emu.cpuType.snes, emu.memType.snesSaveRam)
emu.log("watching bank B1 main region: srm 0x2000-0x3B57")
emu.addMemoryCallback(onSuspectWrite, emu.callbackType.write, 0x4000, 0x5B57,
  emu.cpuType.snes, emu.memType.snesSaveRam)
emu.log("watching bank B2 main region: srm 0x4000-0x5B57")
emu.addMemoryCallback(onCanaryWrite, emu.callbackType.write, 0x1B58, 0x1EBF,
  emu.cpuType.snes, emu.memType.snesSaveRam)
emu.log("canary armed on bank B0 save block: srm 0x1B58-0x1EBF")

emu.log("Play: normal save, suspend save + resume, death, storehouse, rankings, name entry.")
emu.log("Expect CANARY lines on save; hope for zero WRITE lines.")
