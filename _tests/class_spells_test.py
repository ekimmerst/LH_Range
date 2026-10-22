from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'LH_Tweaks' / '.test-runtime'))
exec((Path(__file__).parent / 'range_test.py').read_text())
lua.execute('''
class='MAGE'; targetExists=true; targetAttackable=true; targetFriendly=false
local saved=LH_RangeDB
assert(LH_RangeClassDB and LH_RangeClassDB~=saved)
assert(not LH_Range:GetClassSpells().custom)
assert(not LH_Range:SetClassSpells({[20]=false}))
assert(not LH_RangeClassDB.MAGE)
assert(LH_Range:SetClassSpells({[20]=100,[30]=1978,melee=2974}))
assert(LH_RangeDB==saved and LH_RangeClassDB.MAGE[20]==100)
local copy=LH_Range:GetClassSpells();copy[20]=999
assert(LH_RangeClassDB.MAGE[20]==100)
melee=0
ranges.Spell2974=0;ranges.Spell100=1;ranges.Spell1978=1
update();assert(text()=='Spell100')
ranges.Spell100=0;update();assert(text()=='Spell1978')
ranges['Fire Blast']=1
assert(LH_Range:SetClassSpell(20,'  Fire Blast  '))
assert(LH_RangeClassDB.MAGE[20]=='Fire Blast')
update();assert(text()=='Fire Blast')
ranges['Fire Blast']=0
ranges.Spell1978=0
IsItemInRange=function(id) if id==34368 then return true end;return nil end
update();assert(text()=='Dead Zone')
IsItemInRange=function(id) if id==34368 then return false end;return nil end
update();assert(text()=='Out of Range')
ranges.Spell2974=1;update();assert(text()=='Melee Range')
class='PRIEST';update();assert(not LH_Range:GetClassSpells().custom)
assert(text()=='Out of Melee Range')
class='MAGE';update();assert(LH_Range:GetClassSpells()[20]=='Fire Blast')
LH_Range:ClearClassSpells();assert(not LH_RangeClassDB.MAGE)
''')
print('PASS: class-wide spell IDs, distance priority, dead zone and reset')
