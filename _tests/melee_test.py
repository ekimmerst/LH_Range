from pathlib import Path

exec((Path(__file__).parent / 'settings_hunter_test.py').read_text())
lua.execute('''
-- Exercise the universal client check for every class without weapon/spell tables.
local classes={'WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','SHAMAN','MAGE',
 'WARLOCK','DRUID','DEATHKNIGHT','MONK','DEMONHUNTER','EVOKER','FUTURE_CLASS'}
targetSelf=false;targetExists=true;targetDead=false;targetAttackable=true;targetFriendly=false
missingStrike=true;distance=6;petExists=false
local nativeResult=false
local nativeQueries=0
GetActionInfo=function(slot) if slot==7 then return 'spell',6603 end end
IsActionInRange=function(slot,unit)
 assert(slot==7 and unit=='target');nativeQueries=nativeQueries+1;return nativeResult
end
local originalRange=playerRange
playerRange=function(name)
 if name=='Spell6603' then return true end -- Deliberately overestimates melee.
 return originalRange(name)
end
local function verifyClasses()
 for _,token in ipairs(classes) do
  class=token;nativeResult=true;update()
  assert(LH_RangeFrame.visible and text()=='Melee Range',token)
  nativeResult=false;update()
  local expected=(token=='HUNTER' and 'Dead Zone') or ((token=='SHAMAN' or token=='WARRIOR') and 'Out of Range') or 'Out of Melee Range'
  assert(text()==expected,token..': '..tostring(text()))
 end
end
verifyClasses();assert(nativeQueries==#classes*2)
-- No Attack button is required: modern player spellbook results are authoritative.
GetActionInfo=nil;IsActionInRange=nil
C_SpellBook.FindSpellBookSlotForSpell=function(id) assert(id==6603);return 9,0 end
C_SpellBook.IsSpellBookItemInRange=function(slot,bank,unit)
 assert(slot==9 and bank==0 and unit=='target');return nativeResult
end
events.scripts.OnEvent(events,'SPELLS_CHANGED')
verifyClasses()
-- Legacy player spellbook discovery uses its own bank, independently of pets.
C_SpellBook=nil
GetNumSpellTabs=function() return 2 end
GetSpellTabInfo=function(tab) return 'Tab','Icon',tab==1 and 0 or 2,2 end
GetSpellBookItemInfo=function(slot,bank)
 assert(bank=='spell');return 'SPELL',slot==3 and 6603 or 123
end
IsSpellInRange=function(name,bank,unit)
 if type(name)=='number' then assert(name==3 and bank=='spell' and unit=='target');return nativeResult end
 return playerRange(name)
end
events.scripts.OnEvent(events,'SPELLS_CHANGED')
verifyClasses()
-- Last resort is the client's Attack spell, never a fixed-distance item.
GetNumSpellTabs=nil;GetSpellTabInfo=nil;GetSpellBookItemInfo=nil
events.scripts.OnEvent(events,'SPELLS_CHANGED')
playerRange=function(name) if name=='Spell6603' then return nativeResult end;return originalRange(name) end
verifyClasses()
class='WARRIOR'
C_Item.IsItemInRange=function() error('Melee must not query item range') end
nativeResult=secret;update();assert(text()=='Out of Range')
nativeResult=nil;update();assert(text()=='Out of Range')
nativeResult=0;update();assert(text()=='Out of Range')
nativeResult=1;update();assert(text()=='Melee Range')
IsSpellInRange=function() error('Unavailable range API') end
update();assert(text()=='Out of Range')
''')
print('PASS: all-class melee, range-validated Attack action/player spellbooks and unavailable data')
lua.execute('''
-- Actual level-11 Hunter case: Attack/Raptor report true at ANY distance.
class='HUNTER';distance=20;petDistance=30;petExists=false;learnedInstant=false
function IsPlayerSpell(id) return id==6603 or id==2973 or id==1978 or (learnedInstant and id==2974) end
function SpellHasRange(name) return name~='Spell6603' and name~='Spell2973' end
function IsSpellInRange(name,bank,unit)
 if type(name)=='number' then assert(name==2 and bank=='pet');return petDistance>=8 and petDistance<=25 end
 if name=='Spell6603' or name=='Spell2973' then return 1 end
 if name=='Spell1978' then return distance>=8 and distance<=35 end
 if name=='Spell2974' and learnedInstant then return distance<=4 end
end
GetActionInfo=function() error('Attack without a range check must not be consulted') end
IsActionInRange=function() return 1 end
local probeCalls=0
function IsItemInRange(id)
 if id==8149 then probeCalls=probeCalls+1;return distance<=5 end
 if id==18904 then return distance<=35 end
 assert(id==34368 or id==33278 or id==29052)
 return nil -- The eight-yard items are unavailable on this client.
end
events.scripts.OnEvent(events,'SPELLS_CHANGED')
for _,d in ipairs({1,4,5}) do distance=d;update();assert(text()=='Melee Range') end
for _,d in ipairs({5.01,6,7.99}) do distance=d;update();assert(text()=='Dead Zone');color(.8,.12,.12) end
for _,d in ipairs({8,20,35}) do distance=d;update();assert(text()=='In Range') end
distance=36;update();assert(text()=='Out of Range')
distance=20;petExists=true;petDistance=20;update();assert(text()=='Spell7371')
petExists=false
-- The same safe fallback works without a melee ability for any class or weapon.
for _,token in ipairs({'WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','SHAMAN','MAGE','WARLOCK','DRUID','DEATHKNIGHT','MONK','DEMONHUNTER','EVOKER'}) do
 class=token;events.scripts.OnEvent(events,'SPELLS_CHANGED')
 distance=4;update();assert(text()=='Melee Range',token)
 distance=20;update();assert(text()~='Melee Range',token)
end
assert(probeCalls>0)
-- Learning Wing Clip enables a real strike check; no reset or relog required.
class='HUNTER';learnedInstant=true;events.scripts.OnEvent(events,'SPELLS_CHANGED')
distance=4;update();assert(text()=='Melee Range')
distance=4.01;update();assert(text()=='Dead Zone')
distance=20;update();assert(text()=='In Range')
-- Modern-only spell range metadata also rejects the unconditional Attack result.
learnedInstant=false;SpellHasRange=nil
C_Spell.SpellHasRange=function(name) return name~='Spell6603' end
events.scripts.OnEvent(events,'SPELLS_CHANGED')
distance=6;update();assert(text()=='Dead Zone')
IsItemInRange=function() return secret end
update();assert(text()=='Range unavailable')
''')
print('PASS: level-11 Hunter, unconditional Attack/Raptor positives, all-class approximate fallback, learned Wing Clip and modern metadata')
lua.execute('''
-- Warrior: Rend = melee (<=5 yd), Charge = 8-25 yd, nothing in between = Dead Zone.
C_Spell.SpellHasRange=nil;SpellHasRange=function(name) return name~='Spell6603' end
class='WARRIOR';distance=20
function IsPlayerSpell(id) return id==772 or id==100 end
function IsSpellInRange(name)
 if name=='Spell772' then return distance<=5 end
 if name=='Spell100' then return distance>=8 and distance<=25 end
end
nearProbe=true
function IsItemInRange(id)
 if id==34368 then if nearProbe then return distance<=8 end return nil end
 if id==33278 or id==29052 then return nil end
 if id==18904 then return distance<=35 end
 if id==8149 then return distance<=5 end
end
events.scripts.OnEvent(events,'SPELLS_CHANGED')
for _,d in ipairs({1,5}) do distance=d;update();assert(text()=='Melee Range',d) end
for _,d in ipairs({5.01,6,7.99}) do distance=d;update();assert(text()=='Dead Zone',d);color(.8,.12,.12) end
for _,d in ipairs({8,15,25}) do distance=d;update();assert(text()=='In Range',d);color(.15,.7,.2) end
for _,d in ipairs({25.01,40}) do distance=d;update();assert(text()=='Out of Range',d) end
-- Without readable 8-yard probes: 35-yd probe proves far; otherwise the approach direction decides.
nearProbe=false
distance=40;update();assert(text()=='Out of Range')
for _,d in ipairs({4,5.01,6,7.99}) do distance=d;update();assert(text()==(d<=5 and 'Melee Range' or 'Dead Zone'),d) end
for _,d in ipairs({8,25}) do distance=d;update();assert(text()=='In Range',d) end
distance=26;update();assert(text()=='Out of Range')
distance=7;update();assert(text()=='Out of Range') -- 35-yd probe true, last zone Out of Range: stays outward.
events.scripts.OnEvent(events,'PLAYER_TARGET_CHANGED')
''')
print('PASS: Warrior Rend melee, Charge range and Dead Zone')
