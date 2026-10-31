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
 for i = #frames, 1, -1 do
  local f = frames[i]
  if f.kind == 'Font' and rawget(f, 'visible') ~= nil then return f end
 end
end
local timer = shownTimer()
assert(timer and not timer.visible)
cooldownActive = true
update()
assert(timer.visible and rawget(timer, 'text') == nil)
assert(cooldownBindingMock.duration.spell == 'Spell100' and cooldownBindingMock.enabled)
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
