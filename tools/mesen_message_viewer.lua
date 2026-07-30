-- mesen_message_viewer.lua
-- Show any message on demand: talk to any NPC (or read any sign) and the game
-- draws the message from the list below instead of that NPC's own line. Each
-- talk steps to the next entry, so the whole list can be checked in a minute
-- without hunting down the characters or scenes that normally trigger it.
--
-- Preloaded with the 15 lines flagged as possibly too wide for the message
-- window, strongest suspect first, plus one already-fixed line as a control.
-- Pair it with mesen_overflow_watch.lua: that logs a hit whenever the renderer
-- has to wrap a line itself, which is the actual failure being looked for.
--
-- USAGE: make a savestate somewhere with an NPC handy (a town is ideal), load
-- and run this, then talk to that NPC over and over. Watch the log for which
-- entry is on screen. Set ONLY below to lock onto one entry and re-check it.
--
-- The messages are drawn in the window belonging to whatever you talked to, so
-- cutscene lines are being checked at NPC-window width; that is the same
-- window in practice, but it is an assumption worth knowing about.

local ONLY = nil -- set to an index (1-16) to lock on one entry, nil to cycle

-- Message ids are the index into TextPointerTable in text.asm, and every
-- TextNNNN label's id is exactly its number (checked: 0 mismatches of 2388).
local cases = {
  { 1635, "46ch Ending/Gaibara: \"That's the legendary Condor...It's beautiful.\" <- strongest suspect" },
  { 1621, "44ch Intro: \"Just a little bit further to the Valley Inn.\"" },
  { 1653, "43ch Ending/Old Man: \"If only I live long enough to see\"" },
  { 1626, "42ch Ending/Koppa: \"[name]! ...Hey, look over there!\" (length depends on your name)" },
  { 2196, "43ch Golden City tablet: \"if at all, but whoever reads these words...\"" },
  { 1879, "43ch Pekeji: \"I promise, I won't screw up again!\"" },
  { 1842, "43ch Pekeji: \"...Feels kind of weird to say it...*blush*\"" },
  { 1870, "42ch Pekeji: \"I want to help you however I can. Please!\"" },
  { 1886, "42ch Pekeji: \"I'll do my best to help you out!\"" },
  { 1910, "42ch Koppa: \"So this is the new restaurant I've\"" },
  { 1793, "42ch #5 Disciple: \"Now that the Master's gotten\"" },
  { 1760, "42ch #5 Disciple: \"here, but at the moment he's got 'Artist's\"" },
  { 1763, "42ch Gaibara: \"....Saruyama! My first disciple!\"" },
  { 1715, "42ch Woman: \"when you see it flying will be granted...\"" },
  { 1808, "42ch Man: \"really can see, can't you! We have proof!\"" },
  { 2288, "CONTROL, already fixed: Plump Man / Golden Condor - should NOT overflow" },
}

-- Only hijack ids that an NPC or sign would ask for. The id space is
-- partitioned by file, and dialogue.asm owns 1590-2339, signs.asm 2340-2365,
-- so this leaves menus, item names, item descriptions and dungeon messages
-- alone instead of replacing every string the game draws.
local TRIGGER_LO, TRIGGER_HI = 1590, 2365

local TEXT_ENTRY = 0xC4B94F -- text id arrives in DP $00-$01
local WRAM = emu.memType.snesWorkRam

local idx = 0
local forced = -1

local function dp()
  local ok, st = pcall(emu.getState)
  if not ok or type(st) ~= "table" then return 0 end
  return st["cpu.d"] or (st.cpu and st.cpu.d) or 0
end

emu.addMemoryCallback(function()
  local d = dp()
  local orig = emu.read(d, WRAM) + emu.read(d + 1, WRAM) * 256
  if orig < TRIGGER_LO or orig > TRIGGER_HI then return end -- not a dialogue request
  if orig == forced then return end                         -- our own id coming back around

  if ONLY then
    idx = ONLY
  else
    idx = idx % #cases + 1
  end
  local c = cases[idx]
  forced = c[1]
  emu.write(d, forced % 256, WRAM)
  emu.write(d + 1, math.floor(forced / 256), WRAM)
  emu.log(string.format("%2d/%d  id $%04X (%d) replacing $%04X  %s",
    idx, #cases, forced, forced, orig, c[2]))
end, emu.callbackType.exec, TEXT_ENTRY, TEXT_ENTRY)

emu.log(string.format("message viewer armed (%d entries) - talk to an NPC to step through", #cases))
