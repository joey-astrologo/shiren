-- mesen_flush_check.lua
-- Check the dungeon messages whose trailing \l (line flush) was restored,
-- without hunting down the trap, scroll, staff or NPC that normally shows each.
--
-- HOW IT WORKS: hooks DisplayMessage ($C62525). The FIRST message of each
-- burst (any message after QUIET_FRAMES of silence) is swapped for the next
-- entry in the list below; the messages after it in the same burst play
-- normally. Attacking a monster is the ideal trigger: the swapped message
-- replaces "You attacked X!" and the real damage message follows it, which
-- is exactly the pairing that exposed the bug.
--
-- USAGE: load a savestate inside a dungeon next to a weak monster, run this
-- script, then attack. Each attack steps to the next entry; the Script Window
-- log says which one is on screen. Set ONLY to an index to repeat one entry.
--
-- WHAT A PASS LOOKS LIKE, for every entry:
--   1. The whole message is visible, including its LAST line.
--   2. The message after it starts at the LEFT EDGE of a new line.
-- WHAT THE BUG LOOKED LIKE: the last line is missing (a one-line message
-- shows an empty box), and the next message starts mid-row, indented by the
-- width of the missing line, sometimes wrapping a word ("Iron S / hield").
--
-- Strings like [item]/[monster] and numbers come from whatever the game last
-- bound, so they may be odd or stale. That's expected here; only the line
-- layout matters.
--
-- To see the broken version, run the same script on a ROM built from the
-- commit before the fix; the entries marked FIXED should then show the bug.

local ONLY = nil         -- set to an index (1..#cases) to lock on one entry
local QUIET_FRAMES = 90  -- ~1.5s with no message starts a new burst

local cases = {
  {  145, "CONTROL (fixed earlier)  \"the shield you are equipping / will become stronger.\"" },
  { 2307, "FIXED  \"[name] cast a / purification spell.\"  (Decrepit Old Man)" },
  { 2308, "FIXED  \"All your bracers were identified.\"  (one line: was a blank box)" },
  {   34, "FIXED  \"[monster]'s legs are / trapped and cannot move!\"  (bear trap)" },
  {  184, "FIXED  \"Oh! The staircase / was a monster!\"" },
  {  134, "FIXED  \"Your max HP dropped by N points.\"  (one line: was a blank box)" },
  {   80, "FIXED  \"Your satiation level / became N%.\"" },
  {   21, "FIXED  \"[item] changed / into a Big Rice Ball.\"" },
  {  185, "FIXED  \"But you can't see / anything right now.\"" },
  {  130, "FIXED  \"You can't see so you can't / read it.\"" },
  {   97, "FIXED  \"You'll be able to see the / layout of the dungeon.\"" },
  {  126, "FIXED  \"you can transform monsters / into something else.\"" },
  {  146, "FIXED  \"the weapon you are equipping / will become more powerful.\"" },
  {  186, "FIXED  5 lines, ends \"...you can fire it with / the L button.\"" },
}

local DISPLAY_MESSAGE  = 0xC62525 -- message id in DP $00-$01
local DISPLAY_MESSAGE1 = 0xC62B7E -- watched only, to keep the burst timer honest
local WRAM = emu.memType.snesWorkRam

local frame = 0
local lastMsgFrame = -100000
local idx = 0

local function dp()
  local ok, st = pcall(emu.getState)
  if not ok or type(st) ~= "table" then return 0 end
  return st["cpu.d"] or (st.cpu and st.cpu.d) or 0
end

emu.addEventCallback(function() frame = frame + 1 end, emu.eventType.endFrame)

emu.addMemoryCallback(function()
  local d = dp()
  local orig = emu.read(d, WRAM) + emu.read(d + 1, WRAM) * 256
  local quiet = frame - lastMsgFrame
  lastMsgFrame = frame

  if quiet < QUIET_FRAMES then
    emu.log(string.format("        then id %d (real follow-up: should start at the left edge)", orig))
    return
  end

  idx = ONLY or (idx % #cases + 1)
  local c = cases[idx]
  emu.write(d, c[1] % 256, WRAM)
  emu.write(d + 1, math.floor(c[1] / 256), WRAM)
  emu.log(string.format("%2d/%d  id %d replacing %d  %s", idx, #cases, c[1], orig, c[2]))
end, emu.callbackType.exec, DISPLAY_MESSAGE, DISPLAY_MESSAGE)

emu.addMemoryCallback(function()
  lastMsgFrame = frame
end, emu.callbackType.exec, DISPLAY_MESSAGE1, DISPLAY_MESSAGE1)

emu.log(string.format("flush check armed (%d entries) - attack a monster to step through", #cases))
