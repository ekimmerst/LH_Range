from pathlib import Path
import sys

addon = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(addon.parent / 'LH_Tweaks' / '.test-runtime'))
support = addon.parent / 'LH_AuraBars' / '_tests' / '.lua-test-support.py'
exec(support.read_text().split('lua.execute((pathlib.Path(__file__)')[0])
lua.execute('''
class='ROGUE'; powerType=3; power=40; maximum=100; melee=true
function UnitClass() return class,class end
function UnitCanAssist() return false end
function UnitIsUnit() return false end
function IsSpellInRange(name) return melee end
function IsItemInRange() return melee end
function UnitPowerType() return powerType end
function UnitPower() return power end
function UnitPowerMax() return maximum end
function issecretvalue(value) return value=='secret' end
''')
lua.execute((addon / 'LH_Range.lua').read_text(), 'LH_Range')
lua.execute('''
local events=frames[#frames]
events.scripts.OnEvent(events,'ADDON_LOADED','LH_Range')
local function update() events.scripts.OnUpdate(events,.11) end
local function display()
 local label,fill
 for _,frame in ipairs(frames) do
  if frame.kind=='Font' then label=frame end
  if frame.kind=='StatusBar' and frame.parent==LH_RangeFrame then fill=frame end
 end
 return label.text,fill
end
local text,fill=display()
assert(text=='40/100' and fill.value==.4 and fill.color[1]==1 and fill.color[2]==.82)
power=65;update();text,fill=display();assert(text=='65/100' and fill.value==.65)
melee=false;update();text,fill=display();assert(text=='Out of Melee Range' and fill.value==1)
melee=true;class='WARRIOR';powerType=1;power=25;update()
text,fill=display();assert(text=='25/100' and fill.value==.25 and fill.color[1]==.8)
class='DRUID';powerType=0;update();text,fill=display();assert(text=='Melee Range' and fill.value==1)
powerType=3;update();text,fill=display();assert(text=='25/100' and fill.color[1]==.8)
power='secret';update();text,fill=display();assert(text=='Melee Range' and fill.value==1)
print('PASS: melee resource ticker, colors, power changes and fallback')
''')
