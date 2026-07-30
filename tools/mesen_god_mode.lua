-- mesen_god_mode.lua
-- Testing convenience: get through dungeons fast without dying, so deep floors,
-- signs and NPC dialogue can be reached and checked. Nothing here is a ROM
-- change - it pins a few WRAM values and rewrites one damage byte.
--
-- USAGE: load a save/state, then load and run this script. Flip the switches
-- below to taste. Don't save the game with this running if you care about the
-- save file.

local INVINCIBLE = true  -- $7E89A6: the game's own invincibility turn counter
local NO_HUNGER  = true  -- $7E8943: keep hunger pinned at max
local ONE_SHOT   = true  -- force every hit Shiren lands to maximum damage
local PIN_HP     = false -- hold HP at max (blunter; try INVINCIBLE first)

local HIT_DAMAGE = 0xFF  -- damage dealt per hit when ONE_SHOT is on (byte)

-- Shiren is entity $13 - the last slot of the 20-entry wChar* arrays. The game
-- addresses his fields as base+$13 (e.g. $8618 = wCharMaxHP+$13), and the
-- damage routine below identifies him with cpy #$13.
local PLAYER = 0x13

-- WRAM offsets for emu.memType.snesWorkRam ($7Exxxx -> 0x0xxxx)
local INVINC_TURNS = 0x89A6         -- decremented per turn; damage is zeroed while nonzero
local HUNGER       = 0x8943         -- word
local MAX_HUNGER   = 0x8945         -- word
local CHAR_HP      = 0x85F1 + PLAYER
local CHAR_MAX_HP  = 0x8605 + PLAYER

-- func_C22A25 applies a damage byte: it pushes the damage, then checks whether
-- the target (Y) is Shiren and, if he is invincible, overwrites the pushed copy
-- with zero. This hook sits just past that push and overwrites the same stack
-- byte - but only when the target is NOT Shiren.
local DAMAGE_PUSHED = 0xC22A28

local WRAM = emu.memType.snesWorkRam

local function rd(a) return emu.read(a, WRAM) end
local function wr(a, v) emu.write(a, v, WRAM) end

local function cpu()
  local ok, st = pcall(emu.getState)
  if not ok or type(st) ~= "table" then return nil end
  return st
end

if ONE_SHOT then
  emu.addMemoryCallback(function()
    local st = cpu()
    if not st then return end
    local y  = st["cpu.y"]  or (st.cpu and st.cpu.y)  or 0
    local sp = st["cpu.sp"] or (st.cpu and st.cpu.sp) or 0
    if y % 256 == PLAYER then return end   -- leave damage aimed at Shiren alone
    wr((sp + 1) % 0x10000, HIT_DAMAGE)     -- the byte STA $01,S would write
  end, emu.callbackType.exec, DAMAGE_PUSHED, DAMAGE_PUSHED)
end

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

emu.log(string.format("god mode: invincible=%s no_hunger=%s one_shot=%s pin_hp=%s",
  tostring(INVINCIBLE), tostring(NO_HUNGER), tostring(ONE_SHOT), tostring(PIN_HP)))
