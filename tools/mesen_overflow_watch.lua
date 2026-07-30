-- mesen_overflow_watch.lua
-- Report every line of text that the renderer has to hard-wrap by itself.
--
-- The message renderer checks, per glyph, whether pen_x + glyph_width exceeds
-- the window's pixel limit ($7FDECA,x); if it does it calls the same newline
-- routine that a \l calls ($C5E81A) and drops the glyph onto the next line.
-- There is no word awareness, so an overlong line splits mid-word ("wonderfully
-- i" / "n"). Every hit below is a line that needs a \l added in text/*.asm.
--
-- USAGE: load the script, then play/talk normally. Each auto-wrap logs the text
-- id that was being drawn, so it can be found in text/*.asm by its TextNNNN
-- label. Ids repeat while a box is on screen; only the first hit per id is
-- logged unless VERBOSE is set.

local VERBOSE = false

local TEXT_ENTRY = 0xC4B94F -- "print text": text id sits in DP $00-$01
local AUTO_WRAP  = 0xC5E928 -- the width check's overflow branch

local WRAM = emu.memType.snesWorkRam
local curId = -1
local seen = {}
local hits = 0

emu.addMemoryCallback(function()
  curId = emu.read(0x0, WRAM) + emu.read(0x1, WRAM) * 256
end, emu.callbackType.exec, TEXT_ENTRY, TEXT_ENTRY)

emu.addMemoryCallback(function()
  if not VERBOSE and seen[curId] then return end
  seen[curId] = true
  hits = hits + 1
  emu.log(string.format("%3d. OVERFLOW in text id $%04X (%d) - line is too long, needs a \\l",
    hits, curId, curId))
end, emu.callbackType.exec, AUTO_WRAP, AUTO_WRAP)

emu.log("overflow watch armed - any line the game has to wrap itself will be logged")
