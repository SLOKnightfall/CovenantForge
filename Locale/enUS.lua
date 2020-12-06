local addonName, addon = ...
local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true, true)

if not L then return end

_G["BINDING_HEADER_COVENANTFORGE"] = addonName
_G["BINDING_NAME_COVENANTFORGE_BINDING_TOGGLE_SOULBINDS"] = "Toggle Soulbind Viewer"

--Options
L["General Options"] = true
L["Show Soulbind Name"] = true
L["Show Node Ability Names"] = true
L["Show Weight as Percent"] = true


L["PR"] = "Pre Raid"
L["T26"] = "Tier 26"
--L["Base: %s/%s\nCurrent: %s/%s\nMax Total: %s"] = true
L["Base: %s/%s\nCurrent: %s/%s"] = true

