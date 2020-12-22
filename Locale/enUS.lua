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
L["Show Weights"] = true
L["Hide Weight Values That Are 0"] = true
L["Show Weight as Percent"] = true
L["Disable FX"] = true
L["Show Conduit Rank On Tooltip"] = true
--L["Soulbind Frame Scale"] = true

--Tabs
L["Learned Conduits"] = true
L["Conduits"] = true
L["Weights"] = true
L["Avaiable Conduits"]= true
L["Saved Paths"] = true


L["PR"] = "HERODAMAGE - Pre Raid"
L["T26"] = "HERODAMAGE -Tier 26"
--L["Base: %s/%s\nCurrent: %s/%s\nMax Total: %s"] = true
L["Base: %s/%s\nCurrent: %s/%s"] = true
L["%s - Rank:%s |cffffffff(%s)|r"] = true

L["Current: %s/%s\nMax Possible: %s"] = true
L["%s (Rank %d)"] = true

COVENATNFORGE_UPDATE_PATH = "Update Path"
COVENATNFORGE_DELETE_PATH = "Delete Path"
COVENATNFORGE_CREATE_PATH = "Create Path"

--Saved Paths
L["Name Already Exists"] = true
L["Requires the Forge of Bonds to modify."] = true
L["Saved Path %s has been loaded."] = true



L["Percent Value"] = true

L["Soulbinds"] = true
L["All"] = true

L["Create New Blank Profile"] = true
L["Copy Current Profile"] = true
L["Delete Current Profile"] = true



--[=[
--# CovenantForge.lua
L["Options"]
L["General Options"]
L["Show Soulbind Name"]
L["Show Node Ability Names"]
L["Show Weights"]
L["Hide Weight Values That Are 0"]
L["Show Weight as Percent"]
L["Disable FX"]
L["Show Conduit Rank On Tooltip"]
L["Learned Conduits"]
L["Saved Paths"]
L["Avaiable Conduits"]
L["Weights"]
L["Conduits"]
L["Soulbinds"]
L["Current: %s/%s\nMax Possible: %s"]
L["%s (Rank %d)"]


--# Weights.lua
L["Percent Value"]
L["Create New Blank Profile"]
L["Copy Current Profile"]
L["Delete Current Profile"]



--# SavedPath.lua
L["Requires the Forge of Bonds to modify."]
L["Saved Path %s has been loaded."]
L["Name Already Exists"]

--]=]