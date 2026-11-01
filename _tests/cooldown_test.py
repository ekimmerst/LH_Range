from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'LH_Tweaks' / '.test-runtime'))
support = Path(__file__).resolve().parents[2] / 'LH_AuraBars/_tests/.lua-test-support.py'
exec(support.read_text().split('lua.execute((pathlib.Path(__file__)')[0])
lua.execute('''
class = 'WARRIOR'
function UnitClass() return 'Warrior', class end
function IsSpellInRange(name) if name == 'Spell772' then return 0 end; return ranges[name] end
function SpellHasRange(name) return name == 'Spell6603' end
function IsItemInRange() return 0 end
ranges = {Spell100 = 1}
local methods = getmetatable(UIParent).__index
function methods:IsShown() return self.visible end
function methods:GetStringWidth() return #(rawget(self, 'text') or '') * 4 end
C_Spell = {
 GetSpellName = function(id) return 'Spell' .. id end,
 GetSpellCooldown = function(spell)
  return {isActive = cooldownActive, isOnGCD = gcdOnly}
 end,
 GetSpellCooldownDuration = function(spell, ignoreGCD)
  assert(ignoreGCD)
  return {spell = spell}
 end,
}
C_DurationUtil = {CreateDurationTextBinding = function()
 cooldownBindingMock = setmetatable({}, {__index = {
  SetFontString = function(self, value) self.font = value end,
  SetFormatter = function() end,
  SetZeroDurationText = function() end,
  SetExpiredText = function() end,
  SetUpdateInterval = function() end,
  SetEnabled = function(self, value) self.enabled = value end,
  SetDuration = function(self, value) self.duration = value end,
 }})
 return cooldownBindingMock
end}
C_StringUtil = {CreateSecondsFormatter = function() return setmetatable({},
 {__index = {SetDefaultAbbreviation = function() end}}) end}
Enum = {SecondsFormatterAbbreviation = {OneLetter = 1}}
''')
source = Path(__file__).resolve().parents[1] / 'LH_Range.lua'
lua.execute(source.read_text(), 'LH_Range')
lua.execute('''
local events = frames[#frames]
events.scripts.OnEvent(events, 'ADDON_LOADED', 'LH_Range')
local function update() events.scripts.OnUpdate(events, .11) end
local function shownTimer()
 return cooldownBindingMock.font
end
local timer = shownTimer()
assert(timer and not timer.visible)
cooldownActive = true
update()
assert(timer.visible and rawget(timer, 'text') == nil)
assert(cooldownBindingMock.duration.spell == 'Spell100' and cooldownBindingMock.enabled)
local fill, label, closing
for _, f in ipairs(frames) do
 if f.kind == 'StatusBar' and not fill then fill = f end
 if f.kind == 'Font' and f ~= timer then
  if f.text == ')' then closing = f else label = f end
 end
end
assert(label.text == 'In Range (' and closing.visible)
assert(label.point[1] == 'LEFT' and label.point[3] == 'CENTER')
timer:SetText('3s')
events.scripts.OnUpdate(events, .01)
assert(label.point[4] == -(#label.text + #timer.text + #closing.text) * 2)
assert(fill.color[2] == .7 * .45)
ranges.Spell100 = 1
cooldownActive = false
update()
assert(label.text == 'In Range' and not closing.visible and not timer.visible)
assert(fill.color[2] > .7)
for i = 1, 6 do update() end
assert(fill.color[2] == .7)
cooldownActive = true
update()
ranges.Spell100 = 0
update()
assert(not timer.visible)
ranges.Spell100 = 1
gcdOnly = true
update()
assert(not timer.visible)
gcdOnly = false
cooldownActive = false
update()
assert(not timer.visible)
cooldownActive = true
assert(LH_Range:SetClassSpells({[20] = 'Custom Charge'}))
ranges['Custom Charge'] = 1
update()
assert(timer.visible)
assert(cooldownBindingMock.duration.spell == 'Custom Charge')
targetExists = false
update()
assert(not LH_RangeFrame.visible)
''')
print('PASS: selected spell cooldown timer and GCD filtering')
