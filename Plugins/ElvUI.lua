--[[
	Elvui Plugin to reskin new/changed UI
]]

if not IsAddOnLoaded("ElvUI") then return end
local addonName, addon = ...


local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule('Skins')

local _G = _G
local select = select
local ipairs, pairs, unpack = ipairs, pairs, unpack

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

local MyPlugin = E:NewModule(addonName, 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0') --Create a plugin within ElvUI and adopt AceHook-3.0, AceEvent-3.0 and AceTimer-3.0. We can make use of these later.
local EP = LibStub("LibElvUIPlugin-1.0") --We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.


local function LoadSkin_ElvUI()
--DropDownMenu
end


function MyPlugin:Initialize()
	--Register plugin so options are properly inserted when config is loaded
	EP:RegisterPlugin(addonName, MyPlugin.InsertOptions)
	
end


local textures = {"Ability_Monk_EssenceFont","Ability_Druid_FocusedGrowth","70_inscription_steamy_romance_novel_kit", "INV_Stone_WeightStone_06" }
function S:CovenantForge()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.collections) then return end
	if not CovForge_PathStorage then addon.ElvUIDelay = S.CovenantForge; return  end
	local frame = _G["CovForge_PathStorage"]
	S:HandleButton(frame.CreateButton)
	S:HandleEditBox(frame.EditBox)
	frame.EditBox:SetHeight(20)
	frame.EditBox:ClearAllPoints()
	frame.EditBox:SetPoint("TOPLEFT",frame.Title, "BOTTOMLEFT",-75, -5)

	for i, frame in ipairs(addon.PathStorageFrame.TabList) do
		frame:StripTextures()
		frame:CreateBackdrop()
		frame.backdrop:SetAllPoints()
		frame:StyleButton(nil, true)

		frame.TabardEmblem:SetTexture(("Interface/ICONS/%s"):format(textures[i]))
	end
end

S:AddCallbackForAddon('CovenantForge') 
E:RegisterModule(addonName)  --Register the module with ElvUI. ElvUI will now call MyPlugin:Initialize() when ElvUI is ready to load our plugin.
