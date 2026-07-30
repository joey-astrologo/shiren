-- mesen_overflow_watch.lua
-- Report every line of text that the renderer has to break by itself.
--
-- The renderer checks, per glyph, whether pen_x + glyph_width exceeds the
-- window's pixel limit ($7FDECA,x). There is no word awareness, so an overlong
-- line breaks wherever it happens to be. There are two such checks and they
-- recover differently:
--
--   $C5E928  in func_C5E8E3 - calls the newline routine ($C5E81A), so the line
--            wraps mid-word inside the same box ("wonderfully i" / "n")
--   $C5E95B  in the routine at $C5E93F - calls the page flush ($C5EBBD), so the
--            overflow lands in a whole new text box (a sign showing one stray
--            quote mark on its own page)
--
-- Both mean the same thing: the line does not fit and needs a \l, or in the
-- case of a sign, less leading padding in its textfunction $0 $NN.
--
-- USAGE: load the script, then play/talk/read signs normally. Each hit logs the
-- text id being drawn, which maps to a TextNNNN label in text/*.asm. Only the
-- first hit per id is logged unless VERBOSE is set.

local VERBOSE = false

local TEXT_ENTRY = 0xC4B94F -- "print text": text id sits in DP $00-$01
local WRAP_LINE  = 0xC5E928 -- overflow -> newline within the box
local WRAP_PAGE  = 0xC5E95B -- overflow -> flush to a new box

local WRAM = emu.memType.snesWorkRam
local curId = -1
local seen = {}
local hits = 0

emu.addMemoryCallback(function()
  curId = emu.read(0x0, WRAM) + emu.read(0x1, WRAM) * 256
end, emu.callbackType.exec, TEXT_ENTRY, TEXT_ENTRY)

local function report(kind, detail)
  return function()
    local key = kind .. curId
    if not VERBOSE and seen[key] then return end
    seen[key] = true
    hits = hits + 1
    emu.log(string.format("%3d. OVERFLOW/%s in text id $%04X (%d) - %s",
      hits, kind, curId, curId, detail))
  end
end

emu.addMemoryCallback(report("wrap", "line too long, wrapped mid-word"),
  emu.callbackType.exec, WRAP_LINE, WRAP_LINE)

emu.addMemoryCallback(report("page", "line too long, spilled into a new box"),
  emu.callbackType.exec, WRAP_PAGE, WRAP_PAGE)

emu.log("overflow watch armed (both the wrap and the page-flush paths)")
