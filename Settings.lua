local addonName = ...
local Addon = LH_Range
local variables = {}
function Addon:RefreshSettings()
    if self.notifying or not Settings or not Settings.NotifyUpdate then return end
    self.notifying = true
    for _, variable in ipairs(variables) do Settings.NotifyUpdate(variable) end
    self.notifying = false
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
local function Build(category, layout)
    Addon.category = category
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Target range"))
    local enabled = Proxy(category, "enabled", "boolean", "Enable the range bar", true,
        function() return Addon:GetOption("enabled") end, function(v) Addon:SetEnabled(v) end)
    Settings.CreateCheckbox(category, enabled, "Show melee range for every class, plus spell-range zones for Shamans and Hunters. Disabling hides the bar immediately. Saved per character.")
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
