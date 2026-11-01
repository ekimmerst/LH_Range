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
local tokens={[0]='MANA',[1]='RAGE',[2]='FOCUS',[3]='ENERGY',[6]='RUNIC_POWER'}
function UnitPowerType() return powerType,tokens[powerType] end
function UnitPower() return power end
function UnitPowerMax() return maximum end
function issecretvalue(value) return value=='secret' end
Enum={StatusBarInterpolation={ExponentialEaseOut=1}}
local methods=getmetatable(UIParent).__index
function methods:CreateTexture() return CreateFrame('Texture',nil,self) end
function methods:GetWidth() return rawget(self,'width') or 140 end
function methods:SetValue(value,interpolation) self.value=value;self.interpolation=interpolation end
function methods:SetFormattedText(format,value)
 self.text=value=='secret' and '45' or string.format(format,value)
 self.formattedValue=value
end
function methods:SetVertexColor(r,g,b) self.vertex={r,g,b} end
function methods:GetStatusBarTexture()
 if not rawget(self,'barTexture') then self.barTexture=CreateFrame('Texture',nil,self) end
 return self.barTexture
end
function methods:ClearAllPoints() self.points={} end
function methods:SetPoint(...)
 local points=rawget(self,'points') or {}
 points[#points+1]={...}
 self.points=points
end
''')
lua.execute((addon / 'LH_Range.lua').read_text(), 'LH_Range')
lua.execute('''
local events=frames[#frames]
events.scripts.OnEvent(events,'ADDON_LOADED','LH_Range')
local function update() events.scripts.OnUpdate(events,.11) end
local function display()
 local label,fill,loss,gainGlow,lossGlow,protectedGainGlow,protectedLossGlow
 for _,frame in ipairs(frames) do
  if frame.kind=='Font' and not label then label=frame end
  if frame.kind=='StatusBar' and frame.parent==LH_RangeFrame then
   if not fill then fill=frame else loss=frame end
  end
  if frame.kind=='Texture' and frame.parent==fill and rawget(frame,'vertex') then
   if frame.vertex[2]==1 then
    if not gainGlow then gainGlow=frame else protectedGainGlow=frame end
   else
    if not lossGlow then lossGlow=frame else protectedLossGlow=frame end
   end
  end
 end
 return label.text,fill,loss,gainGlow,lossGlow,label,protectedGainGlow,protectedLossGlow
end
local text,fill,loss,gainGlow,lossGlow,label,protectedGainGlow,protectedLossGlow=display()
assert(text=='40' and fill.value==40 and fill.maximum==100 and fill.color[1]==1 and fill.color[2]==.82)
assert(not gainGlow.visible and not lossGlow.visible)
power=65;events.scripts.OnEvent(events,'UNIT_POWER_UPDATE','player');text=display()
assert(text=='65' and fill.value==65 and gainGlow.visible and not lossGlow.visible)
assert(gainGlow.points[1][4]==56 and gainGlow.points[2][4]==91)
events.scripts.OnEvent(events,'UNIT_POWER_UPDATE','target')
assert(fill.value==65 and gainGlow.visible)
power=35;update();text=display()
assert(text=='35' and fill.value==35 and lossGlow.visible and not gainGlow.visible)
assert(lossGlow.points[1][4]==49 and lossGlow.points[2][4]==91)
power=20;update();assert(fill.value==20 and lossGlow.points[1][4]==28 and lossGlow.points[2][4]==49)
update();assert(lossGlow.visible and lossGlow.alpha==1)
for i=1,4 do update() end
assert(lossGlow.visible and lossGlow.alpha<1)
update();assert(not lossGlow.visible)
melee=false;update();text,fill=display();assert(text=='Out of Melee Range' and fill.value==1)
melee=true;class='WARRIOR';powerType=1;power=25;update()
text,fill=display();assert(text=='25' and fill.value==25 and fill.color[1]==.8)
class='DRUID';powerType=0;update();text,fill=display();assert(text=='Melee Range' and fill.value==1)
powerType=3;update();text,fill=display();assert(text=='25' and fill.color[1]==1)
class='HUNTER';powerType=2;power=70;update();text,fill=display()
assert(text=='70' and fill.value==70 and fill.color[2]==.5)
class='DEATHKNIGHT';powerType=6;power=45;update();text,fill=display()
assert(text=='45' and fill.color[3]==1)
power='secret';update();text,fill=display()
assert(text=='45' and label.formattedValue=='secret' and fill.value=='secret' and loss.value=='secret')
assert(loss.visible and rawget(loss,'interpolation')==nil and protectedGainGlow.visible and protectedLossGlow.visible)
assert(not gainGlow.visible and not lossGlow.visible)
update();assert(loss.interpolation==1)
assert(protectedLossGlow.points[1][2]==fill.barTexture and protectedLossGlow.points[2][2]==loss.barTexture)
assert(protectedGainGlow.points[1][2]==loss.barTexture and protectedGainGlow.points[2][2]==fill.barTexture)
power=20;powerType=0;update();text,fill=display()
assert(text=='Melee Range' and fill.value==1 and fill.maximum==1)
print('PASS: resource value, gained and spent segments, fade and protected-value geometry')
''')
