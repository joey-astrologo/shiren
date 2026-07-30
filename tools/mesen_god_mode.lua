-- mesen_god_mode.lua
-- Testing convenience: keep Shiren alive while walking a dungeon to check
-- something on a deep floor. Nothing here is a ROM change - it just pins a few
-- WRAM values every frame.
--
-- USAGE: load a save/state, then load and run this script. Flip the switches
-- below to taste. Don't save the game with this running if you care about the
-- save file.

local INVINCIBLE = true  -- $7E89A6: the game's own invincibility turn counter
local NO_HUNGER  = true  -- $7E8943: keep hunger pinned at max
local PIN_HP     = false -- $7E85F1: hold HP at max (blunter; try INVINCIBLE first)

-- WRAM offsets for emu.memType.snesWorkRam ($7Exxxx -> 0x0xxxx)
local INVINC_TURNS = 0x89A6 -- decremented once per turn; damage is zeroed while nonzero
local HUNGER       = 0x8943 -- word
local MAX_HUNGER   = 0x8945 -- word
local CHAR_HP      = 0x85F1 -- wCharHP[], Shiren is entity 0
local CHAR_MAX_HP  = 0x8605 -- wCharMaxHP[]

local WRAM = emu.memType.snesWorkRam

local function rd(a) return emu.read(a, WRAM) end
local function wr(a, v) emu.write(a, v, WRAM) end

emu.addEventCallback(function()
  -- Held at 0xFF rather than poked once: at 0 the game prints
  -- "You are no longer invincible." and stops zeroing damage.
  if INVINCIBLE and rd(INVINC_TURNS) ~= 0xFF then wr(INVINC_TURNS, 0xFF) end

  if NO_HUNGER then
    local lo, hi = rd(MAX_HUNGER), rd(MAX_HUNGER + 1)
    if rd(HUNGER) ~= lo or rd(HUNGER + 1) ~= hi then
      wr(HUNGER, lo)
      wr(HUNGER + 1, hi)
    end
  end

  if PIN_HP then
    local max = rd(CHAR_MAX_HP)
    if max > 0 and rd(CHAR_HP) ~= max then wr(CHAR_HP, max) end
  end
end, emu.eventType.endFrame)

emu.log(string.format("god mode: invincible=%s no_hunger=%s pin_hp=%s",
  tostring(INVINCIBLE), tostring(NO_HUNGER), tostring(PIN_HP)))
