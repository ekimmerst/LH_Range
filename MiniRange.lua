local ADDON_NAME = ...
local bar, fill, label, handle, resizing
local spells = {}
local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return GetSpellInfo(id) end
end
local function RefreshSpells()
    spells.bolt = SpellName(403)
    spells.shock = SpellName(8050)
    spells.heal = SpellName(331)
    spells.attack = SpellName(6603)
end
local function InRange(name)
    if not name then return false end
    local query = IsSpellInRange or (C_Spell and C_Spell.IsSpellInRange)
    if not query then return false end
    local ok, result = pcall(query, name, "target")
    return ok and (result == 1 or result == true)
end
local function MeleeRange()
    if InRange(spells.attack) then return true end
    -- Attack range on an action slot includes the target's combat reach.
    if GetActionInfo and IsActionInRange then
        for slot = 1, 120 do
            local kind, id = GetActionInfo(slot)
            if kind == "spell" and id == 6603 then
                local result = IsActionInRange(slot, "target")
                if result ~= nil then return result == 1 or result == true end
            end
        end
    end
    -- Classic's standard 5-yard item probe also works without owning the item.
    local query = IsItemInRange or (C_Item and C_Item.IsItemInRange)
    if query then
        local ok, result = pcall(query, 8149, "target")
        return ok and (result == 1 or result == true)
    end
    return false
end
local function StandardWidth()
    local reference = MiniExpBarFrame or Minimap
    return reference and reference:GetWidth() * reference:GetEffectiveScale() / bar:GetEffectiveScale() or 140
end
local function UpdateSize()
    bar:SetSize(math.max(70, StandardWidth() * MiniRangeDB.widthFactor), 20 * MiniRangeDB.heightFactor)
end
local function SavePosition()
    local x, y = bar:GetCenter()
    if not x or not y then return end
    local scale = bar:GetEffectiveScale() / UIParent:GetEffectiveScale()
    MiniRangeDB.position = {x = x * scale, y = y * scale}
    bar:ClearAllPoints()
    bar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * scale, y * scale)
end
local function StopMoving()
    bar:StopMovingOrSizing()
    SavePosition()
end
local function FinishResize()
    if resizing then resizing = nil; SavePosition() end
end
local function RestorePosition()
    bar:ClearAllPoints()
    local p = MiniRangeDB.position
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        bar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", p.x, p.y)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    end
end
local function UpdateRange()
    if not bar then return end
    if UnitIsUnit("player", "target") then bar:Hide(); return end
    local _, class = UnitClass("player")
    local attackable = UnitCanAttack("player", "target")
    local friendly = UnitCanAssist("player", "target")
    local valid = class == "SHAMAN" and UnitExists("target") and (attackable or friendly) and not UnitIsDeadOrGhost("target")
    if not valid and MiniRangeDB.locked then bar:Hide(); return end
    local text, r, g, b = "Out of Range", 0.8, 0.12, 0.12
    if valid then
        -- Attackable targets use offensive checks even when also assistable.
        if friendly and not attackable then
            if InRange(spells.heal) then text, r, g, b = spells.heal, 0.15, 0.7, 0.2 end
        elseif MeleeRange() then text, r, g, b = "Melee Range", 0.45, 0.45, 0.45
        elseif InRange(spells.shock) then text, r, g, b = spells.shock, 0.15, 0.7, 0.2
        elseif InRange(spells.bolt) then text, r, g, b = spells.bolt, 0.15, 0.7, 0.2 end
    else text, r, g, b = "MiniRange", 0.45, 0.45, 0.45 end
    label:SetText(text)
    fill:SetStatusBarColor(r, g, b, 1)
    bar:Show()
end
local function SetLocked(locked)
    StopMoving()
    FinishResize()
    MiniRangeDB.locked = locked
    bar:EnableMouse(not locked)
    handle:SetShown(not locked)
    UpdateRange()
end
local function Initialize()
    MiniRangeDB = type(MiniRangeDB) == "table" and MiniRangeDB or {}
    if MiniRangeDB.locked == nil then MiniRangeDB.locked = true end
    for _, key in ipairs({"widthFactor", "heightFactor"}) do
        local value = MiniRangeDB[key]
        MiniRangeDB[key] = type(value) == "number" and math.max(0.5, math.min(2, value)) or 1
    end
    bar = CreateFrame("Frame", "MiniRangeFrame", UIParent, "BackdropTemplate")
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
    fill:SetStatusBarTexture("Interface\\AddOns\\MiniRange\\Media\\Smooth.tga")
    fill:SetMinMaxValues(0, 1)
    fill:SetValue(1)
    fill:EnableMouse(false)
    label = fill:CreateFontString(nil, "OVERLAY")
    label:SetPoint("CENTER")
    label:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    label:SetTextColor(1, 1, 1, 1)
    label:SetShadowColor(0, 0, 0, 1)
    label:SetShadowOffset(1, -1)
    bar:SetScript("OnDragStart", function() if not MiniRangeDB.locked and not resizing then bar:StartMoving() end end)
    bar:SetScript("OnDragStop", StopMoving)
    handle = CreateFrame("Button", "MiniRangeResizeHandle", bar)
    handle:SetSize(16, 16)
    handle:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
    handle:SetFrameLevel(bar:GetFrameLevel() + 10)
    handle:EnableMouse(true)
    local circle = handle:CreateTexture(nil, "ARTWORK")
    circle:SetAllPoints()
    circle:SetTexture("Interface\\Buttons\\UI-RadioButton")
    circle:SetTexCoord(0.25, 0.5, 0, 1)
    handle:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or MiniRangeDB.locked then return end
        StopMoving()
        local x, y = GetCursorPosition()
        local scale = bar:GetEffectiveScale()
        local left, top = bar:GetLeft(), bar:GetTop()
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * scale / UIParent:GetEffectiveScale(), top * scale / UIParent:GetEffectiveScale())
        resizing = {x = x / scale, y = y / scale, width = MiniRangeDB.widthFactor, height = MiniRangeDB.heightFactor, base = StandardWidth()}
    end)
    handle:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then FinishResize() end end)
    handle:SetScript("OnHide", FinishResize)
    bar:SetScript("OnHide", function() StopMoving(); FinishResize() end)
    RefreshSpells()
    UpdateSize()
    RestorePosition()
    bar:EnableMouse(not MiniRangeDB.locked)
    handle:SetShown(not MiniRangeDB.locked)
    UpdateRange()
end
local events = CreateFrame("Frame")
for _, event in ipairs({"ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "SPELLS_CHANGED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == ADDON_NAME and not bar then Initialize() end
    elseif bar then
        if event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then RefreshSpells() end
        UpdateSize()
        UpdateRange()
    end
end)
local elapsedTotal = 0
events:SetScript("OnUpdate", function(_, elapsed)
    if not bar then return end
    if resizing then
        if not IsMouseButtonDown("LeftButton") then FinishResize()
        else
            local x, y = GetCursorPosition()
            local scale = bar:GetEffectiveScale()
            MiniRangeDB.widthFactor = math.max(0.5, math.min(2, resizing.width + (x / scale - resizing.x) / resizing.base))
            MiniRangeDB.heightFactor = math.max(0.5, math.min(2, resizing.height + (resizing.y - y / scale) / 20))
            UpdateSize()
        end
    end
    elapsedTotal = elapsedTotal + elapsed
    if elapsedTotal >= 0.1 then elapsedTotal = 0; UpdateSize(); UpdateRange() end
end)
SLASH_MINIRANGE1 = "/minirange"
SLASH_MINIRANGE2 = "/minirang"
SlashCmdList.MINIRANGE = function(message)
    if not bar then return end
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if command == "lock" or command == "unlock" then
        SetLocked(command == "lock")
        print(MiniRangeDB.locked and "MiniRange: Position locked." or "MiniRange: Drag the bar to move; drag the circle to resize.")
    elseif command == "reset" then
        StopMoving(); FinishResize()
        MiniRangeDB.position = nil
        MiniRangeDB.widthFactor, MiniRangeDB.heightFactor = 1, 1
        UpdateSize(); RestorePosition(); UpdateRange()
    else print("MiniRange: /minirange unlock | lock | reset") end
end
