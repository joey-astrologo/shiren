-- mesen_areatitle_test.lua
-- Force the floor-announcement banner to render a chosen (area title, floor)
-- pair, so the double-digit layout can be checked without playing all the way
-- to that dungeon.
--
-- USAGE: load a save/state inside ANY dungeon, load and run this script, then
-- change floors. Each floor transition shows the next case in the list below;
-- after the last one it wraps around. The override is written on entry to
-- DisplayAreaTitle and undone the instant it returns, so the HUD, the map and
-- the save file never see the fake values. Still: use a savestate, and don't
-- save the game with the script running.

-- areaId ($7ED5F9), floor number ($7ED5F2), label
local cases = {
  { 0x38, 16, "Cave of the Wall Scroll 16F" },
  { 0x30, 16, "Shrine of the Food God 16F" },
  { 0x30, 99, "Shrine of the Food God 99F" },
  { 0x77, 24, "Foot of the Rainbow 24F" },
  { 0x14, 12, "Mountain Spirit Cave 12F (control: already correct before the fix)" },
  { 0x1A, 17, "Table Mountain 17F (control)" },
}

-- WRAM offsets for emu.memType.snesWorkRam ($7Exxxx -> 0x0xxxx)
local AREA  = 0xD5F9 -- area title id
local FLOOR = 0xD5F2 -- wFloorNum
local TOWN  = 0xD5F8 -- wIsInTown: nonzero = draw the floor number

local ENTRY = 0xC5CC1E -- DisplayAreaTitle
local EXIT  = 0xC5CD7F -- its rtl

local WRAM = emu.memType.snesWorkRam
local idx = 0
local saved = nil

local function rd(a) return emu.read(a, WRAM) end
local function wr(a, v) emu.write(a, v, WRAM) end

local function restore()
  if not saved then return end
  wr(AREA, saved.area)
  wr(FLOOR, saved.floor)
  wr(TOWN, saved.town)
  saved = nil
end

emu.addMemoryCallback(function()
  restore() -- in case a previous call somehow skipped the exit hook
  idx = idx % #cases + 1
  local c = cases[idx]
  saved = { area = rd(AREA), floor = rd(FLOOR), town = rd(TOWN) }
  wr(AREA, c[1])
  wr(FLOOR, c[2])
  wr(TOWN, 1)
  emu.log(string.format("case %d/%d: area=%02X floor=%d  %s   (real: area=%02X floor=%d)",
    idx, #cases, c[1], c[2], c[3], saved.area, saved.floor))
end, emu.callbackType.exec, ENTRY, ENTRY)

emu.addMemoryCallback(function()
  restore()
end, emu.callbackType.exec, EXIT, EXIT)

emu.log("area-title test loaded: change floors to step through " .. #cases .. " cases")
