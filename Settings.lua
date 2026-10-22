local addonName = ...
local Addon = LH_Range
local variables = {}
local spellPanels = {}
function Addon:RefreshSettings()
    if self.notifying or not Settings or not Settings.NotifyUpdate then return end
    self.notifying = true
    for _, variable in ipairs(variables) do Settings.NotifyUpdate(variable) end
    self.notifying = false
    for _, panel in ipairs(spellPanels) do panel:RefreshSpells() end
end
local function Proxy(category, key, kind, label, default, get, set)
    local variable = "LH_Range_" .. key
    variables[#variables + 1] = variable
    return Settings.RegisterProxySetting(category, variable, kind, label, default, get, set)
end
local function Defaults()
    SlashCmdList.LH_RANGE("lock")
    SlashCmdList.LH_RANGE("reset")
end

LHRangeSpellPanelMixin = {}
function LHRangeSpellPanelMixin:OnLoad()
    spellPanels[#spellPanels + 1] = self
    self.fields = {}
    local note = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 8, -4)
    note:SetWidth(440)
    note:SetJustifyH("LEFT")
    note:SetText("Enter localized ability names or spell IDs. Press Enter or leave a field to save; leave melee empty for automatic detection.")
    self.note = note
    for index, row in ipairs({{"melee", "Melee"}, {8, "8 yards"}, {10, "10 yards"}, {20, "20 yards"}, {30, "30 yards"}, {40, "40 yards"}}) do
        local key = row[1]
        local caption = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        caption:SetPoint("TOPLEFT", 12, -49 - (index - 1) * 33)
        caption:SetText(row[2])
        local field = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
        field:SetSize(240, 24)
        field:SetPoint("TOPLEFT", 180, -43 - (index - 1) * 33)
        field:SetAutoFocus(false)
        field:SetMaxLetters(120)
        field:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
        field:SetScript("OnEscapePressed", function(box)
            box:SetText(Addon:GetClassSpell(key))
            box:ClearFocus()
        end)
        field:SetScript("OnEditFocusLost", function(box)
            Addon:SetClassSpell(key, box:GetText())
            box:SetText(Addon:GetClassSpell(key))
        end)
        self.fields[key] = field
    end
end

function LHRangeSpellPanelMixin:Init()
    self:RefreshSpells()
end

function LHRangeSpellPanelMixin:OnShow()
    self:RefreshSpells()
end

function LHRangeSpellPanelMixin:RefreshSpells()
    if not self.fields then return end
    for key, field in pairs(self.fields) do
        if not field:HasFocus() then field:SetText(Addon:GetClassSpell(key)) end
    end
end
local function Build(category, layout)
    Addon.category = category
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Target range"))
    local enabled = Proxy(category, "enabled", "boolean", "Enable the range bar", true,
        function() return Addon:GetOption("enabled") end, function(v) Addon:SetEnabled(v) end)
    Settings.CreateCheckbox(category, enabled, "Show melee range and configured spell distances for your class. Disabling hides the bar immediately. Saved per character.")
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Class spells"))
    layout:AddInitializer(Settings.CreatePanelInitializer("LHRangeSpellPanelTemplate", {name = "Spells for current class"}))
    layout:AddInitializer(CreateSettingsButtonInitializer("Use built-in class behavior", "Clear spells", function() Addon:ClearClassSpells() end,
        "Remove custom spells for this class and use the built-in range checks.", true))
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Position and size"))
    local unlock = Proxy(category, "unlocked", "boolean", "Unlock and preview the range bar", false,
        function() return not Addon:GetOption("locked") end,
        function(v) SlashCmdList.LH_RANGE(v and "unlock" or "lock") end)
    Settings.CreateCheckbox(category, unlock, "While enabled, left-drag the bar to move it; drag the circle below its right edge to resize. Lock to hide the circle. Saved per character.")
    for _, option in ipairs({{key="widthFactor",label="Bar width"},{key="heightFactor",label="Bar height"}}) do
        local key = option.key
        local setting = Proxy(category, key, "number", option.label, 100,
            function() return Addon:GetOption(key)*100 end, function(v) Addon:SetSizeFactor(key,v/100) end)
        local options = Settings.CreateSliderOptions(50,200,5)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,function(v) return string.format("%.0f%%",v) end)
        Settings.CreateSlider(category,setting,options,"Size relative to the default. Width follows LH_ExpBar or the minimap, with a 70-unit minimum. Default height is 20 UI units. Font size stays at 12 points. Saved per character.")
    end
    layout:AddInitializer(CreateSettingsButtonInitializer("Restore the default size and position", "Reset layout",
        function() SlashCmdList.LH_RANGE("reset") end,"Restore default dimensions and the position below screen center. Keep activation and lock settings.",true))
    EventRegistry:RegisterCallback("Settings.CategoryDefaulted",function(_,selected) if selected==category then Defaults() end end,Addon)
    EventRegistry:RegisterCallback("Settings.Defaulted",Defaults,Addon)
end
LH_Tweaks:RegisterModule(addonName,"LH Range",Build)
