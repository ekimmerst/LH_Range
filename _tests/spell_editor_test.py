from pathlib import Path

exec((Path(__file__).parent / 'settings_hunter_test.py').read_text())
lua.execute('''
local methods=getmetatable(UIParent).__index
function methods:GetText() return self.text end
function methods:HasFocus() return false end
local initializer
for _,row in ipairs(registered.layout.rows) do
 if row.template=='LHRangeSpellPanelTemplate' then initializer=row end
end
assert(initializer and not LH_RangeSpellEditor)
class='HUNTER'
local panel=CreateFrame('Frame',nil,UIParent)
for key,value in pairs(LHRangeSpellPanelMixin) do panel[key]=value end
panel:OnLoad();panel:Init()
assert(panel.fields[30]:GetText()=='Spell1978')
assert(panel.fields.melee:GetText()=='')
local characterDB=LH_RangeDB
panel.fields.melee:SetText('Wing Clip')
panel.fields.melee.scripts.OnEditFocusLost(panel.fields.melee)
assert(LH_RangeClassDB.HUNTER.melee=='Wing Clip')
assert(LH_RangeClassDB.HUNTER[30]==1978 and LH_RangeDB==characterDB)
panel.fields[30]:SetText('Serpent Sting')
panel.fields[30].scripts.OnEditFocusLost(panel.fields[30])
assert(LH_RangeClassDB.HUNTER[30]=='Serpent Sting')
buttons['Clear spells']()
assert(not LH_RangeClassDB.HUNTER)
assert(panel.fields[30]:GetText()=='Spell1978')
''')
print('PASS: inline class spell fields save names and restore built-in behavior')
