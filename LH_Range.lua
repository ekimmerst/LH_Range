local ADDON_NAME = ...
local Addon = {}
LH_Range = Addon
local bar, fill, label, handle, resizing
local spells = {}
local petCharge
local meleeBook
local meleeStrikes = {}
-- Instant targeted strikes, not next-swing modifiers such as Raptor Strike.
local meleeSpellIDs = {
    HUNTER = {2974, 1495}, WARRIOR = {772}, ROGUE = {1752},
    PALADIN = {35395}, SHAMAN = {73899}, DRUID = {22568, 33917},
    DEATHKNIGHT = {49998}, MONK = {100780}, DEMONHUNTER = {162794},
}
local maximumProbeRequested = false
local meleeProbeRequested = false
local distanceSlots = {8, 10, 20, 30, 40}
local defaultClassSpells = {
    HUNTER = {[30] = 1978},
    WARRIOR = {[20] = 100},
    SHAMAN = {[20] = 8042, [30] = 8050, [40] = 403},
}
local currentClass
local function Public(value) return not (issecretvalue and issecretvalue(value)) end
local function RangeResult(query, ...)
    if type(query) ~= "function" then return nil end
    local ok, result = pcall(query, ...)
    if not ok or not Public(result) then return nil end
    if result == true or result == 1 then return true end
    if result == false or result == 0 then return false end
end
local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return GetSpellInfo(id) end
end
local function RefreshSpells()
    spells.bolt = SpellName(403)
    spells.earthShock = SpellName(8042)
    spells.shock = SpellName(8050)
    spells.heal = SpellName(331)
    spells.attack = SpellName(6603)
    spells.sting = SpellName(1978)
    spells.charge = SpellName(100)
    meleeStrikes = {}
    local _, class = UnitClass("player")
    local known = IsPlayerSpell or IsSpellKnown
    for _, id in ipairs(meleeSpellIDs[class] or {}) do
        if not known or RangeResult(known, id) == true then
            local name = SpellName(id)
            if name then meleeStrikes[#meleeStrikes + 1] = name end
        end
    end
    meleeBook = nil
    if C_SpellBook and C_SpellBook.FindSpellBookSlotForSpell then
        local ok, slot, bank = pcall(C_SpellBook.FindSpellBookSlotForSpell, 6603)
        if ok and Public(slot) and type(slot) == "number" and Public(bank) then
            meleeBook = {slot = slot, bank = bank, modern = true}
        end
    elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo then
        for tab = 1, GetNumSpellTabs() do
            local _, _, offset, count = GetSpellTabInfo(tab)
            for slot = offset + 1, offset + count do
                local kind, id = GetSpellBookItemInfo(slot, "spell")
                if Public(kind) and Public(id) and kind == "SPELL" and id == 6603 then
                    meleeBook = {slot = slot, bank = "spell", modern = false}
                    break
                end
            end
            if meleeBook then break end
        end
    end
    -- Populate the Classic-era maximum-range probe before a near-range check.
    if not maximumProbeRequested and C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(18904)
        maximumProbeRequested = true
    end
    if not meleeProbeRequested and C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(8149)
        meleeProbeRequested = true
    end
    petCharge = nil
    local chargeName = SpellName(7371)
    local modern = C_SpellBook and C_SpellBook.HasPetSpells and C_SpellBook.GetSpellBookItemInfo
        and Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    local getCount = modern and C_SpellBook.HasPetSpells or HasPetSpells
    if not chargeName or type(getCount) ~= "function" then return end
    local ok, count = pcall(getCount)
    if not ok or not Public(count) or type(count) ~= "number" then return end
    for slot = 1, count do
        local name
        if modern then
            local info = C_SpellBook.GetSpellBookItemInfo(slot, Enum.SpellBookSpellBank.Pet)
            if info then name = info.name or (info.spellID and SpellName(info.spellID)) end
        elseif GetSpellBookItemName then
            name = GetSpellBookItemName(slot, "pet")
        elseif GetSpellBookItemInfo then
            local kind, id = GetSpellBookItemInfo(slot, "pet")
            if kind == "SPELL" then name = SpellName(id) end
        end
        if Public(name) and name == chargeName then
            petCharge = {slot = slot, modern = modern and true or false, name = name}
            break
        end
    end
end
local function InRange(name)
    if not name then return nil end
    local query = IsSpellInRange or (C_Spell and C_Spell.IsSpellInRange)
    if not query then return nil end
    return RangeResult(query, name, "target")
end

local function ClassSpells()
    local classes = type(LH_RangeClassDB) == "table" and LH_RangeClassDB
    return classes and type(classes[currentClass]) == "table" and classes[currentClass] or nil
end

local function ConfiguredSpell(id)
    if type(id) == "string" then
        return id ~= "" and id or nil
    end
    if type(id) ~= "number" or id < 1 or id % 1 ~= 0 then return nil end
    local known = IsPlayerSpell or IsSpellKnown
    if known and RangeResult(known, id) ~= true then return nil end
    return SpellName(id)
end
local function ApproximateMelee()
    local query = IsItemInRange or (C_Item and C_Item.IsItemInRange)
    local near = RangeResult(query, 8149, "target")
    if near == false then return false end
    -- A five-yard item can exclude melee, but cannot prove weapon reach.
    if near == true then return nil, true end
end
local function MeleeRange()
    local config = ClassSpells()
    if config and config.melee then
        local name = ConfiguredSpell(config.melee)
        if name then
            local result = InRange(name)
            if result ~= nil then return result end
        end
    end
    for _, name in ipairs(meleeStrikes) do
        local strike = InRange(name)
        if strike ~= nil then return strike end
    end
    -- Attack can return 1 even at long distance when no range check exists.
    -- Never interpret that value as evidence of melee reach.
    local hasRange = SpellHasRange or (C_Spell and C_Spell.SpellHasRange)
    if RangeResult(hasRange, spells.attack) ~= true then return ApproximateMelee() end
    local getAction = GetActionInfo or (C_ActionBar and C_ActionBar.GetActionInfo)
    local actionRange = IsActionInRange or (C_ActionBar and C_ActionBar.IsActionInRange)
    if getAction and actionRange then
        for slot = 1, 120 do
            local ok, kind, id = pcall(getAction, slot)
            if ok and Public(kind) and Public(id) and kind == "spell" and id == 6603 then
                local result = RangeResult(actionRange, slot, "target")
                if result ~= nil then return result end
            end
        end
    end
    if meleeBook then
        local query
        if meleeBook.modern then
            query = C_SpellBook and C_SpellBook.IsSpellBookItemInRange
        else
            query = IsSpellInRange
        end
        local result = RangeResult(query, meleeBook.slot, meleeBook.bank, "target")
        if result ~= nil then return result end
    end
    local attack = InRange(spells.attack)
    if attack ~= nil then return attack end
    return ApproximateMelee()
end

local WithinEightYards, WithinStingMaximum, PetChargeInRange
local function ConfiguredRange()
    local config = ClassSpells()
    if not config or not config.custom then return nil end
    local melee, approximate = MeleeRange()
    if melee == true or (melee == nil and approximate) then
        return "Melee Range", .45, .45, .45
    end
    local first, rejected = nil, false
    for _, yards in ipairs(distanceSlots) do
        local name = ConfiguredSpell(config[yards])
        if name then
            local result = InRange(name)
            if result == true and not first then first = name end
            if result == false then rejected = true end
        end
    end
    local near
    if rejected and not first then
        near = WithinEightYards()
        if near == true then return "Dead Zone", .8, .12, .12 end
    end
    if currentClass == "HUNTER" and PetChargeInRange() == true then
        return petCharge.name, 1, .82, 0
    end
    if first then return first, .15, .7, .2 end
    if near == false then return "Out of Range", .8, .12, .12 end
    if rejected and WithinStingMaximum() == false then return "Out of Range", .8, .12, .12 end
    if rejected then return "Range unavailable", .45, .45, .45 end
    if melee == false then return "Out of Melee Range", .8, .12, .12 end
    return "Range unavailable", .45, .45, .45
end
function WithinEightYards()
    local query = IsItemInRange or (C_Item and C_Item.IsItemInRange)
    -- Eight-yard probes listed by LibRangeCheck; no library dependency.
    for _, id in ipairs({34368, 33278, 29052}) do
        local result = RangeResult(query, id, "target")
        if result ~= nil then return result end
    end
end
function WithinStingMaximum()
    local query = IsItemInRange or (C_Item and C_Item.IsItemInRange)
    -- Zorbin's Ultra-Shrinker is a Classic-era 35-yard probe. Unlike the
    -- eight-yard items above, it does not require later-expansion item data.
    return RangeResult(query, 18904, "target")
end
function PetChargeInRange()
    if not petCharge or RangeResult(UnitExists, "pet") ~= true
        or RangeResult(UnitIsDeadOrGhost, "pet") ~= false then return nil end
    if petCharge.modern and C_SpellBook and C_SpellBook.IsSpellBookItemInRange then
        return RangeResult(C_SpellBook.IsSpellBookItemInRange, petCharge.slot, Enum.SpellBookSpellBank.Pet, "target")
    end
    -- The pet spellbook bank is essential: a player spell query uses a different origin.
    return RangeResult(IsSpellInRange, petCharge.slot, "pet", "target")
end
local function HunterRange()
    local melee, approximate = MeleeRange()
    if melee then return "Melee Range", .45, .45, .45 end
    local sting = InRange(spells.sting)
    local near = sting == false and WithinEightYards()
    if sting == false and near == nil then
        -- A readable maximum-range check disambiguates "too close" from "too far".
        -- Serpent Sting rejects the near interval; melee has already been excluded.
        near = WithinStingMaximum()
    end
    if melee == false and sting == false and near == true then
        return "Dead Zone", .8, .12, .12
    end
    if approximate and sting ~= true and near ~= false then return "Melee Range", .45, .45, .45 end
    if PetChargeInRange() == true then return petCharge.name, 1, .82, 0 end
    if sting == true then return "In Range", .15, .7, .2 end
    if sting == false and near == false then return "Out of Range", .8, .12, .12 end
    return "Range unavailable", .45, .45, .45
end
local warriorZone
local function WarriorRange()
    -- Rend (melee) and Charge (normally 8-25 yards) leave a dead zone between them.
    -- Only four states exist: Melee Range, In Range, Dead Zone, Out of Range.
    local melee, approximate = MeleeRange()
    if melee or (melee == nil and approximate) then warriorZone = "Melee Range"; return warriorZone, .45, .45, .45 end
    local charge = InRange(spells.charge)
    if charge == true then warriorZone = "In Range"; return warriorZone, .15, .7, .2 end
    -- Charge rejects both "too close" and "too far"; item probes tell them apart.
    local near = charge == false and WithinEightYards() or nil
    if charge == false and near == nil and WithinStingMaximum() == false then near = false end
    if charge == false and near == nil then
        -- Probes unreadable: targets leave melee through the dead zone and leave Charge range outward.
        near = warriorZone == "Melee Range" or warriorZone == "Dead Zone"
    end
    if near then warriorZone = "Dead Zone"; return warriorZone, .8, .12, .12 end
    warriorZone = "Out of Range"
    return warriorZone, .8, .12, .12
end
local function StandardWidth()
    local reference = LH_ExpBarFrame or Minimap
    return reference and reference:GetWidth() * reference:GetEffectiveScale() / bar:GetEffectiveScale() or 140
end
local function UpdateSize()
    bar:SetSize(math.max(70, StandardWidth() * LH_RangeDB.widthFactor), 20 * LH_RangeDB.heightFactor)
end
local function SavePosition()
    local x, y = bar:GetCenter()
    if not x or not y then return end
    local scale = bar:GetEffectiveScale() / UIParent:GetEffectiveScale()
    LH_RangeDB.position = {x = x * scale, y = y * scale}
    bar:ClearAllPoints()
    bar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * scale, y * scale)
end
local function StopMoving()
    bar:StopMovingOrSizing()
    SavePosition()
end
local function FinishResize()
    if resizing then
        resizing = nil
        SavePosition()
        if Addon.RefreshSettings then Addon:RefreshSettings() end
    end
end
local function RestorePosition()
    bar:ClearAllPoints()
    local p = LH_RangeDB.position
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        bar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", p.x, p.y)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    end
end
local function UpdateRange()
    if not bar then return end
    if not LH_RangeDB.enabled then bar:Hide(); return end
    local selfTarget = UnitIsUnit("player", "target")
    local _, class = UnitClass("player")
    currentClass = class
    local attackable = UnitCanAttack("player", "target")
    local friendly = UnitCanAssist("player", "target")
    local valid = not selfTarget and UnitExists("target")
        and (attackable or (class == "SHAMAN" and friendly)) and not UnitIsDeadOrGhost("target")
    if not valid and LH_RangeDB.locked then bar:Hide(); return end
    local text, r, g, b = "Out of Range", 0.8, 0.12, 0.12
    if valid then
        -- Attackable targets use offensive checks even when also assistable.
        local config = ClassSpells()
        if config and config.custom and attackable then text, r, g, b = ConfiguredRange()
        elseif class == "HUNTER" then text, r, g, b = HunterRange()
        elseif class == "WARRIOR" then text, r, g, b = WarriorRange()
        elseif class ~= "SHAMAN" then
            local melee, approximate = MeleeRange()
            if melee == true then text, r, g, b = "Melee Range", .45, .45, .45
            elseif melee == false then text, r, g, b = "Out of Melee Range", .8, .12, .12
            elseif approximate then text, r, g, b = "Melee Range", .45, .45, .45
            else text, r, g, b = "Range unavailable", .45, .45, .45 end
        elseif friendly and not attackable then
            if InRange(spells.heal) then text, r, g, b = spells.heal, 0.15, 0.7, 0.2 end
        else
            local melee, approximate = MeleeRange()
            if melee then text, r, g, b = "Melee Range", .45, .45, .45
            elseif approximate then text, r, g, b = "Melee Range", .45, .45, .45
            elseif InRange(spells.earthShock) then text, r, g, b = spells.earthShock, 1, .82, 0
            elseif InRange(spells.shock) then text, r, g, b = spells.shock, 1, .82, 0
            elseif InRange(spells.bolt) then text, r, g, b = spells.bolt, .15, .7, .2 end
        end
    else text, r, g, b = "LH_Range", 0.45, 0.45, 0.45 end
    label:SetText(text)
    fill:SetStatusBarColor(r, g, b, 1)
    bar:Show()
end
local function SetLocked(locked)
    StopMoving()
    FinishResize()
    LH_RangeDB.locked = locked
    bar:EnableMouse(not locked)
    handle:SetShown(not locked)
    UpdateRange()
end
local function Initialize()
    LH_RangeDB = type(LH_RangeDB) == "table" and LH_RangeDB or {}
    LH_RangeClassDB = type(LH_RangeClassDB) == "table" and LH_RangeClassDB or {}
    currentClass = select(2, UnitClass("player"))
    if type(LH_RangeDB.enabled) ~= "boolean" then LH_RangeDB.enabled = true end
    if LH_RangeDB.locked == nil then LH_RangeDB.locked = true end
    for _, key in ipairs({"widthFactor", "heightFactor"}) do
        local value = LH_RangeDB[key]
        LH_RangeDB[key] = type(value) == "number" and math.max(0.5, math.min(2, value)) or 1
    end
    bar = CreateFrame("Frame", "LH_RangeFrame", UIParent, "BackdropTemplate")
    bar:SetFrameStrata("MEDIUM")
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}})
    bar:SetBackdropColor(0, 0, 0, 1)
    bar:SetBackdropBorderColor(0.65, 0.59, 0.45, 1)
    fill = CreateFrame("StatusBar", nil, bar)
    fill:SetPoint("TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", -3, 3)
    fill:SetStatusBarTexture("Interface\\AddOns\\LH_Range\\Media\\Smooth.tga")
    fill:SetMinMaxValues(0, 1)
    fill:SetValue(1)
    fill:EnableMouse(false)
    label = fill:CreateFontString(nil, "OVERLAY")
    label:SetPoint("CENTER")
    label:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    label:SetTextColor(1, 1, 1, 1)
    label:SetShadowColor(0, 0, 0, 1)
    label:SetShadowOffset(1, -1)
    bar:SetScript("OnDragStart", function() if not LH_RangeDB.locked and not resizing then bar:StartMoving() end end)
    bar:SetScript("OnDragStop", StopMoving)
    handle = CreateFrame("Button", "LH_RangeResizeHandle", bar)
    handle:SetSize(16, 16)
    handle:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
    handle:SetFrameLevel(bar:GetFrameLevel() + 10)
    handle:EnableMouse(true)
    local circle = handle:CreateTexture(nil, "ARTWORK")
    circle:SetAllPoints()
    circle:SetTexture("Interface\\Buttons\\UI-RadioButton")
    circle:SetTexCoord(0.25, 0.5, 0, 1)
    handle:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or LH_RangeDB.locked then return end
        StopMoving()
        local x, y = GetCursorPosition()
        local scale = bar:GetEffectiveScale()
        local left, top = bar:GetLeft(), bar:GetTop()
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * scale / UIParent:GetEffectiveScale(), top * scale / UIParent:GetEffectiveScale())
        resizing = {x = x / scale, y = y / scale, width = LH_RangeDB.widthFactor, height = LH_RangeDB.heightFactor, base = StandardWidth()}
    end)
    handle:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then FinishResize() end end)
    handle:SetScript("OnHide", FinishResize)
    bar:SetScript("OnHide", function() StopMoving(); FinishResize() end)
    RefreshSpells()
    UpdateSize()
    RestorePosition()
    bar:EnableMouse(not LH_RangeDB.locked)
    handle:SetShown(not LH_RangeDB.locked)
    UpdateRange()
end
local events = CreateFrame("Frame")
for _, event in ipairs({"ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "SPELLS_CHANGED", "UNIT_PET", "PET_BAR_UPDATE", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == ADDON_NAME and not bar then Initialize() end
    elseif bar then
        if event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD" or event == "UNIT_PET"
            or event == "PET_BAR_UPDATE" then RefreshSpells() end
        if event == "PLAYER_TARGET_CHANGED" then warriorZone = nil end
        UpdateSize()
        UpdateRange()
    end
end)
local elapsedTotal = 0
events:SetScript("OnUpdate", function(_, elapsed)
    if not bar or not LH_RangeDB.enabled then return end
    if resizing then
        if not IsMouseButtonDown("LeftButton") then FinishResize()
        else
            local x, y = GetCursorPosition()
            local scale = bar:GetEffectiveScale()
            LH_RangeDB.widthFactor = math.max(0.5, math.min(2, resizing.width + (x / scale - resizing.x) / resizing.base))
            LH_RangeDB.heightFactor = math.max(0.5, math.min(2, resizing.height + (resizing.y - y / scale) / 20))
            UpdateSize()
        end
    end
    elapsedTotal = elapsedTotal + elapsed
    if elapsedTotal >= 0.1 then elapsedTotal = 0; UpdateSize(); UpdateRange() end
end)
SLASH_LH_RANGE1 = "/lh_range"
function Addon:GetOption(key)
    if LH_RangeDB and LH_RangeDB[key] ~= nil then return LH_RangeDB[key] end
    if key == "enabled" or key == "locked" then return true end
    return 1
end
function Addon:SetEnabled(enabled)
    if not bar then return end
    StopMoving(); FinishResize()
    LH_RangeDB.enabled = enabled == true
    UpdateRange()
    if self.RefreshSettings then self:RefreshSettings() end
end
function Addon:SetSizeFactor(key, value)
    if not bar or (key ~= "widthFactor" and key ~= "heightFactor") or type(value) ~= "number" then return end
    FinishResize()
    LH_RangeDB[key] = math.max(.5, math.min(2, value))
    UpdateSize()
    if self.RefreshSettings then self:RefreshSettings() end
end

function Addon:GetClassSpells()
    local _, class = UnitClass("player")
    local saved = type(LH_RangeClassDB) == "table" and LH_RangeClassDB[class]
    local copy = {}
    if type(saved) == "table" then
        copy.custom = saved.custom == true
        copy.melee = saved.melee
        for _, yards in ipairs(distanceSlots) do copy[yards] = saved[yards] end
    end
    return copy
end

function Addon:GetClassSpell(key)
    local values = self:GetClassSpells()
    local _, class = UnitClass("player")
    local value = values.custom and values[key] or (defaultClassSpells[class] or {})[key]
    if type(value) == "number" then return SpellName(value) or tostring(value) end
    return value or ""
end

function Addon:SetClassSpell(key, value)
    if key ~= "melee" and key ~= 8 and key ~= 10 and key ~= 20 and key ~= 30 and key ~= 40 then return false end
    if type(value) ~= "string" then return false end
    value = value:match("^%s*(.-)%s*$")
    local _, class = UnitClass("player")
    if not class then return false end
    local saved = self:GetClassSpells()
    if not saved.custom then
        for defaultKey, id in pairs(defaultClassSpells[class] or {}) do saved[defaultKey] = id end
    end
    saved[key] = value ~= "" and (tonumber(value) or value) or nil
    saved.custom = true
    LH_RangeClassDB = type(LH_RangeClassDB) == "table" and LH_RangeClassDB or {}
    LH_RangeClassDB[class] = saved
    currentClass = class
    UpdateRange()
    return true
end

function Addon:SetClassSpells(values)
    if type(values) ~= "table" then return false end
    local copy = {custom = true}
    for _, key in ipairs({"melee", 8, 10, 20, 30, 40}) do
        local value = values[key]
        if value ~= nil and value ~= "" then
            if type(value) == "string" then value = value:match("^%s*(.-)%s*$") end
            if type(value) ~= "string" and type(value) ~= "number" then return false end
            if type(value) == "number" and (value < 1 or value % 1 ~= 0) then return false end
            if value ~= "" then copy[key] = tonumber(value) or value end
        end
    end
    local _, class = UnitClass("player")
    if not class then return false end
    LH_RangeClassDB = type(LH_RangeClassDB) == "table" and LH_RangeClassDB or {}
    LH_RangeClassDB[class] = copy
    currentClass = class
    UpdateRange()
    return true
end

function Addon:ClearClassSpells()
    local _, class = UnitClass("player")
    if type(LH_RangeClassDB) == "table" then LH_RangeClassDB[class] = nil end
    UpdateRange()
    if self.RefreshSettings then self:RefreshSettings() end
end
SlashCmdList.LH_RANGE = function(message)
    if not bar then return end
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if command == "on" or command == "off" then
        Addon:SetEnabled(command == "on")
        print(LH_RangeDB.enabled and "LH_Range: Enabled." or "LH_Range: Disabled.")
    elseif command == "lock" or command == "unlock" then
        SetLocked(command == "lock")
        print(LH_RangeDB.locked and "LH_Range: Position locked." or "LH_Range: Drag the bar to move; drag the circle to resize.")
    elseif command == "reset" then
        StopMoving(); FinishResize()
        LH_RangeDB.position = nil
        LH_RangeDB.widthFactor, LH_RangeDB.heightFactor = 1, 1
        UpdateSize(); RestorePosition(); UpdateRange()
    elseif command == "" and Addon.category then Settings.OpenToCategory(Addon.category:GetID())
    else print("LH_Range: /lh_range on | off | unlock | lock | reset") end
    if Addon.RefreshSettings then Addon:RefreshSettings() end
end
