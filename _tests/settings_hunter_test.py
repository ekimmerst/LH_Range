from pathlib import Path
import sys

addon = Path(__file__).resolve().parent.parent
core = addon.parent / 'LH_Tweaks'
sys.path.insert(0, str(core / '.test-runtime'))
# The Shaman regression builds the same Lua 5.1 environment used below.
exec((addon / '_tests/range_test.py').read_text())
lua.execute('''
local originalSpellInfo=GetSpellInfo
GetSpellInfo=function(id) if id==26177 then return 'Spell7371' end;return originalSpellInfo(id) end
class='HUNTER';distance=20;petDistance=30;petExists=true;petDead=false;hasCharge=true
secret={};hiddenRange=false;missingEight=false;missingMaximum=false;missingStrike=false
function issecretvalue(value) return value==secret end
function UnitExists(unit) if unit=='pet' then return petExists end;return targetExists end
function UnitIsDeadOrGhost(unit) if unit=='pet' then return petDead end;return targetDead end
function HasPetSpells() return hasCharge and 2 or 1 end
function GetSpellBookItemName(slot,bank) assert(bank=='pet');return slot==2 and GetSpellInfo(26177) or 'Growl' end
function playerRange(name)
 if name=='Spell1978' then
  if hiddenRange then return secret end
  return distance>=8 and distance<=35
 end
 if name=='Spell6603' then return distance<=5 end
 if name=='Spell2974' or name=='Spell1495' then if missingStrike then return nil end;return distance<=4 end
end
function IsSpellInRange(name,bank,unit)
 if type(name)=='number' then assert(name==2 and bank=='pet' and unit=='target');return petDistance>=8 and petDistance<=25 end
 return playerRange(name)
end
function IsItemInRange(id)
 if id==8149 then return distance<=5 end
 if id==18904 then if missingMaximum then return nil end;return distance<=35 end
 assert(id==34368 or id==33278 or id==29052)
 if missingEight then return nil end
 return distance<=8
end
events.scripts.OnEvent(events,'UNIT_PET','player')
distance=4;update();assert(text()=='Melee Range');color(.45,.45,.45)
for _,d in ipairs({4.01,4.5,5.01,6,7.99}) do distance=d;petDistance=15;update();assert(text()=='Dead Zone');color(.8,.12,.12) end
distance=8;petDistance=30;update();assert(text()=='In Range');color(.15,.7,.2)
distance=20;petDistance=20;update();assert(text()=='Spell7371');color(1,.82,0)
petDistance=25;update();assert(text()=='Spell7371')
petDistance=25.01;update();assert(text()=='In Range')
distance=35;update();assert(text()=='In Range')
distance=35.01;update();assert(text()=='Out of Range');color(.8,.12,.12)
distance=50;petDistance=20;update();assert(text()=='Spell7371','Pet range incorrectly uses player distance')
distance=20;petExists=false;update();assert(text()=='In Range')
petExists=true;petDead=true;update();assert(text()=='In Range')
petDead=false;hasCharge=false;events.scripts.OnEvent(events,'PET_BAR_UPDATE');assert(text()=='In Range')
hasCharge=true;events.scripts.OnEvent(events,'SPELLS_CHANGED');assert(text()=='Spell7371')
-- Modern pet-bank discovery and range checking use the Pet bank, never player spell queries.
Enum={SpellBookSpellBank={Player=0,Pet=1}}
C_SpellBook={HasPetSpells=function() return 2 end,
 GetSpellBookItemInfo=function(slot,bank) assert(bank==1);return {name=slot==2 and 'Spell7371' or 'Growl',spellID=slot==2 and 26177 or 2649} end,
 IsSpellBookItemInRange=function(slot,bank,unit) assert(slot==2 and bank==1 and unit=='target');return petDistance>=8 and petDistance<=25 end}
IsSpellInRange=nil
C_Spell={GetSpellName=GetSpellInfo,IsSpellInRange=function(name,unit) assert(unit=='target');return playerRange(name) end}
events.scripts.OnEvent(events,'PET_BAR_UPDATE');assert(text()=='Spell7371')
petDistance=30;update();assert(text()=='In Range')
hiddenRange=true;update();assert(text()=='Range unavailable')
hiddenRange=false;distance=6;missingEight=true;update();assert(text()=='Dead Zone');color(.8,.12,.12)
-- Missing later-expansion items must not block Classic dead-zone detection.
for _,d in ipairs({5.01,6,7.99}) do distance=d;update();assert(text()=='Dead Zone') end
distance=8;update();assert(text()=='In Range')
distance=35;update();assert(text()=='In Range')
distance=35.01;update();assert(text()=='Out of Range')
distance=6;missingMaximum=true;update();assert(text()=='Range unavailable')
missingMaximum=false;missingEight=false;update();assert(text()=='Dead Zone')
-- Modern item API, cache request and restricted/error fallback.
local itemQuery=IsItemInRange
IsItemInRange=nil;missingEight=true;local requests=0
C_Item={IsItemInRange=itemQuery,RequestLoadItemDataByID=function(id) assert(id==18904 or id==8149);requests=requests+1 end}
events.scripts.OnEvent(events,'SPELLS_CHANGED');events.scripts.OnEvent(events,'SPELLS_CHANGED')
assert(requests==2);update();assert(text()=='Dead Zone')
C_Item.IsItemInRange=function(id,unit) if id==18904 then return secret end;return itemQuery(id,unit) end
update();assert(text()=='Range unavailable')
C_Item.IsItemInRange=function(id,unit) if id==18904 then error('Unavailable item') end;return itemQuery(id,unit) end
update();assert(text()=='Range unavailable')
C_Item.IsItemInRange=itemQuery;missingEight=false
targetAttackable=false;targetFriendly=true;SlashCmdList.LH_RANGE('lock');assert(not LH_RangeFrame.visible)
targetAttackable=true;targetFriendly=false;distance=20
registry={};notices={};buttons={};callbacks={};Settings={}
function Settings.RegisterVerticalLayoutSubcategory(parent,title)
 local c={parent=parent,title=title};function c:GetID() return self.title end
 local l={rows={}};function l:AddInitializer(row) table.insert(self.rows,row) end;c.layout=l;return c,l
end
function Settings.RegisterAddOnCategory(c) registered=c end
function Settings.RegisterProxySetting(c,v,kind,label,default,get,set)
 local s={category=c,default=default,get=get,set=set};registry[v]=s;return s
end
function Settings.CreateCheckbox(c,s,t) c.layout:AddInitializer({setting=s}) end
function Settings.CreateSliderOptions() return {SetLabelFormatter=function() end} end
function Settings.CreateSlider(c,s,o,t) c.layout:AddInitializer({setting=s}) end
function Settings.CreatePanelInitializer(template,data) return {template=template,data=data} end
function Settings.NotifyUpdate(v) notices[v]=(notices[v] or 0)+1 end
function Settings.OpenToCategory(id) opened=id end
function CreateSettingsListSectionHeaderInitializer(t) return {header=t} end
function CreateSettingsButtonInitializer(label,button,fn) buttons[button]=fn;return {label=label} end
MinimalSliderWithSteppersMixin={Label={Right=1}}
EventRegistry={}
function EventRegistry:RegisterCallback(event,fn,owner) callbacks[event]={fn,owner} end
function fire(event,...) local entry=callbacks[event];entry[1](entry[2],...) end
LH_Tweaks={modules={}}
''')
source = (core / 'LH_Tweaks.lua').read_text()
registration = source.split('function Hub:RegisterModule(id, title, build)')[1].split('\nfunction Hub:RestoreDefaults')[0]
lua.execute('local Hub=LH_Tweaks\nfunction Hub:RegisterModule(id, title, build)' + registration)
source = (core / 'Settings.lua').read_text()
registration = source.split('function Hub:RegisterModulePage(id)')[1].split('\nlocal function RegisterSettings')[0]
lua.execute('local Hub=LH_Tweaks\nfunction Hub:RegisterModulePage(id)' + registration)
lua.execute((addon / 'Settings.lua').read_text(), 'LH_Range')
lua.execute('''
assert(LH_Tweaks.modules.LH_Range and not registered)
LH_Tweaks.category={};LH_Tweaks:RegisterModulePage('LH_Range')
assert(registered.parent==LH_Tweaks.category and registered.title=='LH Range')
local enabled,unlock,w,h=registry.LH_Range_enabled,registry.LH_Range_unlocked,registry.LH_Range_widthFactor,registry.LH_Range_heightFactor
enabled.set(false);assert(not LH_RangeFrame.visible)
events.scripts.OnUpdate(events,.5);assert(not LH_RangeFrame.visible)
enabled.set(true);assert(LH_RangeFrame.visible)
unlock.set(true);assert(LH_RangeResizeHandle.visible and not LH_RangeDB.locked)
w.set(150);h.set(75);assert(LH_RangeDB.widthFactor==1.5 and LH_RangeDB.heightFactor==.75)
buttons['Reset layout']();assert(unlock.get() and w.get()==100 and h.get()==100)
w.set(150);fire('Settings.CategoryDefaulted',{});assert(w.get()==150)
fire('Settings.CategoryDefaulted',registered);assert(enabled.get() and not unlock.get() and w.get()==100)
SlashCmdList.LH_RANGE();assert(opened=='LH Range')
SlashCmdList.LH_RANGE('off');assert(not enabled.get() and notices.LH_Range_enabled>0)
SlashCmdList.LH_RANGE('on extra');assert(not enabled.get())
enabled.set(enabled.default);assert(enabled.get())
''')
for ext in ('png', 'tga'):
    assert (addon / f'Media/Icon.{ext}').read_bytes() == (core / f'Icon.{ext}').read_bytes()
print('PASS: Hunter boundaries, red dead zone, actual legacy/modern pet Charge range, pet lifecycle, restricted data, native settings/defaults and shared icons')
