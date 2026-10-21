import pathlib
import sys

support = pathlib.Path(__file__).resolve().parents[2] / 'LH_AuraBars/_tests/.lua-test-support.py'
try:
    import lupa.lua51
except ImportError:
    sys.exit('Test requires lupa with Lua 5.1 support: python -m pip install lupa')
exec(support.read_text().split('lua.execute((pathlib.Path(__file__)')[0])
lua.execute('''
function UnitClass() return 'Shaman', class or 'SHAMAN' end
function IsSpellInRange(name) return ranges[name] end
function IsItemInRange() return melee end
function UnitCanAssist() return targetFriendly end
function UnitIsUnit() return targetSelf end
targetSelf = false
targetFriendly = false
ranges = {}; melee = 0
local m = getmetatable(UIParent).__index
function m:SetShown(value) self.visible = value end
''')
source = pathlib.Path(__file__).resolve().parents[1] / 'LH_Range.lua'
lua.execute(source.read_text(), 'LH_Range')
lua.execute('''
events = frames[#frames]
events.scripts.OnEvent(events, 'ADDON_LOADED', 'LH_Range')
function update() events.scripts.OnUpdate(events, 0.11) end
function text()
 for _, f in ipairs(frames) do if f.kind == 'Font' and f.text then return f.text end end
end
function color(r, g, b)
 for _, f in ipairs(frames) do
  if f.kind == 'StatusBar' then
   assert(f.color[1] == r and f.color[2] == g and f.color[3] == b)
   return
  end
 end
 error('Missing range fill')
end
assert(LH_RangeFrame.visible and text() == 'Out of Range')
targetSelf = true; update(); assert(not LH_RangeFrame.visible)
SlashCmdList.LH_RANGE('unlock'); assert(not LH_RangeFrame.visible)
targetSelf = false; update(); assert(LH_RangeFrame.visible)
SlashCmdList.LH_RANGE('lock')
ranges.Spell403 = 1; update(); assert(text() == 'Spell403')
color(0.15, 0.7, 0.2)
ranges.Spell8050 = 1; update(); assert(text() == 'Spell8050')
color(1, 0.82, 0)
ranges.Spell8042 = 1; update(); assert(text() == 'Spell8042')
color(1, 0.82, 0)
melee = 1; update(); assert(text() == 'Melee Range')
ranges.Spell8042 = 0
targetFriendly = true; ranges.Spell331 = 1
update(); assert(LH_RangeFrame.visible and text() == 'Melee Range')
melee = 0; update(); assert(text() == 'Spell8050')
ranges.Spell8050 = 0; update(); assert(text() == 'Spell403')
ranges.Spell403 = 0; update(); assert(text() == 'Out of Range')
targetAttackable = false; targetFriendly = true
ranges.Spell331 = 1; update(); assert(text() == 'Spell331')
color(0.15, 0.7, 0.2)
ranges.Spell331 = 0; update(); assert(text() == 'Out of Range')
targetDead = true; update(); assert(not LH_RangeFrame.visible)
targetDead = false; targetFriendly = false
update(); assert(not LH_RangeFrame.visible)
targetAttackable = true
targetExists = false; update(); assert(not LH_RangeFrame.visible)
SlashCmdList.LH_RANGE('unlock')
assert(LH_RangeFrame.visible and LH_RangeFrame.mouse and LH_RangeResizeHandle.visible)
assert(text() == 'LH_Range')
mouseDown = true
LH_RangeResizeHandle.scripts.OnMouseDown(nil, 'LeftButton')
cursorX, cursorY = 40, -10; update()
assert(LH_RangeDB.widthFactor > 1 and LH_RangeDB.heightFactor == 1.5)
SlashCmdList.LH_RANGE('lock')
assert(not LH_RangeFrame.mouse and not LH_RangeResizeHandle.visible)
targetExists = true; class = 'MAGE'; update(); assert(not LH_RangeFrame.visible)
SlashCmdList.LH_RANGE('reset')
assert(LH_RangeDB.widthFactor == 1 and LH_RangeDB.heightFactor == 1)
''')
print('LH_Range: range priority, visibility, lock, resize and reset passed.')
