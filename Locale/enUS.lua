local addonName, addon = ...
local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true, true)

if not L then return end

_G["BINDING_HEADER_COVENANTFORGE"] = addonName
_G["BINDING_NAME_COVENANTFORGE_BINDING_TOGGLE_SOULBINDS"] = "Toggle Soulbind Viewer"

--Options
L["Options"] =true
L["General Options"] = true
L["Show Soulbind Name"] = true
L["Show Node Ability Names"] = true
L["Show Weight as Percent"] = true
L["Disable FX"] = true
L["Show Conduit Rank on Tooltip"] = true
L["Soulbind Frame Scale"] = true

--Tabs
L["Weights"] = true
L["Avaiable Conduits"]= true
L["Saved Paths"] = true


L["PR"] = "Pre Raid"
L["T26"] = "Tier 26"
--L["Base: %s/%s\nCurrent: %s/%s\nMax Total: %s"] = true
L["Base: %s/%s\nCurrent: %s/%s"] = true
L["%s - Rank:%s |cffffffff(%s)|r"] = true

L["Current: %s/%s\nMax Possible: %s"] = true
L["%s (Rank %d)"] = true

COVENATNFORGE_UPDATE_PATH = "Update Path"
COVENATNFORGE_DELETE_PATH = "Delete Path"
COVENATNFORGE_CREATE_PATH = "Create Path"