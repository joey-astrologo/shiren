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

-- "dialogue" cycles the long NPC/cutscene lines, "signs" cycles the sign texts.
-- Trigger each set from its own kind of target - talk to an NPC for the
-- dialogue set, read a sign for the sign set - so the message is drawn in the
-- window it would really use. Forcing a sign into an NPC window (or vice versa)
-- tests nothing, because the box is sized before the text is drawn.
local SET = "signs"

local ONLY = nil -- set to an index to lock on one entry, nil to cycle

-- Message ids are the index into TextPointerTable in text.asm, and every
-- TextNNNN label's id is exactly its number (checked: 0 mismatches of 2388).
local dialogue = {
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

-- Signs, longest line first. Estimated extent to the last glyph is in brackets;
-- the limit is ~232px. Only 2364 is meaningfully over - it kept the Japanese
-- full-width bracket layout ("  <pad 53>  text  <pad 53>  ") with English text
-- that is twice as wide as the kanji it replaced.
-- All 26 signs, worst line first. The number is the estimated extent to the
-- last glyph; the limit is ~232px. Treat gaps under ~20px as noise - the
-- estimate is a flat per-character average and has mis-ranked neighbours
-- before. Only 2364 is over by a margin the estimate can actually resolve.
local signs = {
  { 2364, "~317px  \"This is the other side of the Earth\"  <- confirmed broken" },
  { 2347, "~228px  \"Gaibara the Potter\" Works Display Area  <- confirmed good" },
  { 2348, "~218px  \"View of Table Mountain\" / This is truly a breath...  <- confirmed good" },
  { 2349, "~215px  General Store \"Unripened Bamboo Shop\"  <- confirmed good" },
  { 2342, "~207px  Safe to eat / Mountaintop Restaurant \"Gakeppuchi\"  <- fixed, should be clean now" },
  { 2343, "~206px  \"Togeya\" has gone out of business. / I'm upset. -...  <- confirmed good" },
  { 2356, "~204px  Bar \"Smoke and Old Man Pavillion\"" },
  { 2352, "~200px  Deliveryman \"Alleycat's path\"" },
  { 2357, "~193px  Underground River Town Entrance" },
  { 2354, "~192px  Entrance to the Valley Inn" },
  { 2341, "~188px  New store changed! / Restaurant \"Togeya\"" },
  { 2351, "~184px  Bar \"Drunken Pavillion\"" },
  { 2360, "~180px  Underground River Town Exit" },
  { 2340, "~176px  Restaurant \"Togeya\" / Reorganizing" },
  { 2355, "~174px  Inn \"Travelling Crow\"" },
  { 2359, "~172px  Shop \"Clear Stream\"" },
  { 2363, "~170px  Inn \"Boulder Shadow\"" },
  { 2353, "~168px  \"Dedication\" / To Bufoo, God of Food" },
  { 2361, "~166px  \"Golden City Amteca\"" },
  { 2358, "~165px  Inn \"White Dragon\"" },
  { 2345, "~164px  Smithy \"Oni's Club\"" },
  { 2350, "~161px  Smithy \"Immobile\"" },
  { 2344, "~160px  Inn \"Tomariboku\"" },
  { 2365, "~143px  \"Warehouse\"" },
  { 2362, "~143px  \"Warehouse\"" },
  { 2346, "~143px  \"Warehouse\"" },
}

local cases = (SET == "signs") and signs or dialogue

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
