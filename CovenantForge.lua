--  ///////////////////////////////////////////////////////////////////////////////////////////
--
--   
--  Author: SLOKnightfall

--  

--

--  ///////////////////////////////////////////////////////////////////////////////////////////

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0")
--addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
--_G[addonName] = {}
addon.Frame = LibStub("AceGUI-3.0")
addon.Init = {}

local playerInv_DB
local Profile
local playerNme
local realmName
local playerClass, classID,_
local viewed_spec
local conduitList = {}

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local CONDUIT_RANKS = {
	[1] = C_Soulbinds.GetConduitItemLevel(0, 1),
	[2] = C_Soulbinds.GetConduitItemLevel(0, 2),
	[3] = C_Soulbinds.GetConduitItemLevel(0, 3),
	[4] = C_Soulbinds.GetConduitItemLevel(0, 4),
	[5] = C_Soulbinds.GetConduitItemLevel(0, 5),
	[6] = C_Soulbinds.GetConduitItemLevel(0, 6),
	[7] = C_Soulbinds.GetConduitItemLevel(0, 7),
	[8] = C_Soulbinds.GetConduitItemLevel(0, 8),
}

local DB_Defaults = {
	char_defaults = {
		profile = {
			item = {},
			set = {},
			extraset = {},
			outfits = {},
			lastTransmogOutfitIDSpec = {},
			listUpdate = false,
		}
	},
}
local WEIGHT_BASE = 37.75

--ACE3 Option Handlers
local optionHandler = {}
function optionHandler:Setter(info, value)
	addon.Profile[info[#info]] = value
end


function optionHandler:Getter(info)
	return addon.Profile[info[#info]]
end




local options = {
	name = "CovenantForge",
	handler = optionHandler,
	get = "Getter",
	set = "Setter",
	type = 'group',
	childGroups = "tab",
	inline = true,
	args = {
		settings={
			name = L["Options"],
			type = "group",
			inline = false,
			order = 0,
			args = {
				Options_Header = {
					order = 1,
					name = L["General Options"],
					type = "header",
					width = "full",
				},
				
				ShowSoulbindNames = {
					order = 3,
					name = L["Show Soulbind Name"],
					type = "toggle",
					width = "full",
					arg = "ShowSoulbindNames",
				},

				ShowNodeNames = {
					order = 3,
					name = L["Show Node Ability Names"],
					type = "toggle",
					width = "full",
					arg = "ShowNodeNames",
				},

				ShowAsPercent = {
					order = 4,
					name = L["Show Weight as Percent"],
					type = "toggle",
					width = "full",
					arg = "ShowAsPercent",
				},

				disableFX = {
					order = 5,
					name = L["Disable FX"],
					width = "full",
					type = "toggle",
				},

				ShowTooltipRank = {
					order = 6,
					name = L["Show Conduit Rank on Tooltip"],
					type = "toggle",
					width = "full",
				},
			},
		},
	},
}

local defaults = {
	profile = {
				['*'] = true,
				disableFX = false,
			},
}

local pathDefaults = {
	char ={
		paths = {},
	},
}


---Ace based addon initilization
function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("CovenantForgeDB", defaults, true)

	self.savedPathdb = LibStub("AceDB-3.0"):New("CovenantForgeSavedPaths", pathDefaults, true)
	addon.Profile = self.db.profile
	options.args.profiles  = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(options, addonName)
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
	--options.args.path_profiles  = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.savedPathdb)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("CovenantForge", "CovenantForge")
	--self.db.RegisterCallback(OmegaMap, "OnProfileChanged", "RefreshConfig")
	--self.db.RegisterCallback(OmegaMap, "OnProfileCopied", "RefreshConfig")
	--self.db.RegisterCallback(OmegaMap, "OnProfileReset", "RefreshConfig")



	addon:RegisterEvent("ADDON_LOADED", "EventHandler" )

end

function addon:EventHandler(event, arg1 )
	if event == "ADDON_LOADED" and arg1 == "Blizzard_Soulbinds" then 
		C_Timer.After(0, function() addon.Init:CreateSoulbindFrames() end)

		self:SecureHook(SoulbindViewer, "Open", function()  C_Timer.After(.05, function() addon:Update() end) end , true)
			--addon:Hook(ConduitListConduitButtonMixin, "Init", "ConduitRank", true)
		self:SecureHook(SoulbindViewer, "SetSheenAnimationsPlaying", "StopAnimationFX")
		self:SecureHook(SoulbindTreeNodeLinkMixin, "SetState", "StopNodeFX")
		self:UnregisterEvent("ADDON_LOADED")
	end

end

local SoulbindConduitNodeEvents =
{
	"SOULBIND_CONDUIT_INSTALLED",
	"SOULBIND_CONDUIT_UNINSTALLED",
	"SOULBIND_PENDING_CONDUIT_CHANGED",
	"SOULBIND_CONDUIT_COLLECTION_UPDATED",
	"SOULBIND_CONDUIT_COLLECTION_REMOVED",
	"SOULBIND_CONDUIT_COLLECTION_CLEARED",
	"PLAYER_SPECIALIZATION_CHANGED",
	"SOULBIND_NODE_LEARNED",
	"SOULBIND_PATH_CHANGED",
}

function addon:OnEnable()
	addon:BuildWeightData()
	addon:GetConduits()
	local spec = GetSpecialization()
	viewed_spec = GetSpecializationInfo(spec)

	self:SecureHookScript(GameTooltip, "OnTooltipSetItem", "GenerateToolip")
	self:SecureHookScript(ItemRefTooltip, "OnTooltipSetItem", "GenerateToolip")
	self:SecureHookScript(EmbeddedItemTooltip,"OnTooltipSetItem", "GenerateToolip")
end

local CLASS_SPECS ={{71,72,73},{65,66,70},{253,254,255},{259,260,261},{256,257,258},{250,251,252},{262,263,264},{62,63,64},{265,266,267},{268,269,270},{102,103,104,105},{577,578}}

local covenantBgAtlasIDs = {
	[1] = "ui-frame-kyrianchoice-cardparchment",
	[2] = "ui-frame-venthyrchoice-cardparchment",
	[3] = "ui-frame-nightfaechoice-cardparchment",
	[4] = "ui-frame-necrolordschoice-cardparchment",
}

local scroll
local scrollcontainer
function addon.Init:CreateSoulbindFrames()
	local frame = CreateFrame("Frame", "CovForge_events", SoulbindViewer)
	
	frame:SetScript("OnShow", function() FrameUtil.RegisterFrameForEvents(frame, SoulbindConduitNodeEvents) end)
	frame:SetScript("OnHide", function() FrameUtil.UnregisterFrameForEvents(frame, SoulbindConduitNodeEvents) end)
	frame:SetScript("OnEvent", addon.Update)
	--frame:Show()
	FrameUtil.RegisterFrameForEvents(frame, SoulbindConduitNodeEvents);
	local covenantID = C_Covenants.GetActiveCovenantID();
	--local soulbindID = C_Soulbinds.GetActiveSoulbindID();

	local spec = GetSpecialization()
	local specID, specName = GetSpecializationInfo(spec)
	--local soulbindData = C_Soulbinds.GetSoulbindData(1).name;

	--SoulbindViewer.SelectGroup
	for buttonIndex, button in ipairs(SoulbindViewer.SelectGroup.buttonGroup:GetButtons()) do
		addon:Hook(button, "OnSelected", function() addon:Update() end , true)

		local f = CreateFrame("Frame", "CovForge_Souldbind"..buttonIndex, button, "CovenantForge_SoulbindInfoTemplate")
		button.ForgeInfo = f
	end

	for buttonIndex, nodeFrame in pairs(SoulbindViewer.Tree:GetNodes()) do
		local f = CreateFrame("Frame", "CovForge_Conduit"..buttonIndex, nodeFrame, "CovenantForge_ConduitInfoTemplate")
		nodeFrame.ForgeInfo = f
	end

	local _, _, classID = UnitClass("player")
	local classSpecs = CLASS_SPECS[classID]
	local dropdownList = {}
	for index,ID in ipairs(classSpecs) do
		local specID, specName = GetSpecializationInfo(index)
		dropdownList[ID] = specName
	end

	--Spec Selection Dropdown
	local frame = AceGUI:Create("SimpleGroup")
	frame.frame:SetParent(SoulbindViewer)
	frame:SetHeight(20)
	frame:SetWidth(125)
	frame:SetPoint("TOP",SoulbindViewer,"TOP", 105, -33)
	frame:SetLayout("Fill")
	local dropdown = AceGUI:Create("Dropdown")
	frame:AddChild(dropdown)
	dropdown:SetList(dropdownList)
	local spec = GetSpecialization()
	local specID = GetSpecializationInfo(spec)
	dropdown:SetValue(specID)
	dropdown:SetCallback("OnValueChanged", function(self,event, key) viewed_spec = key; addon:Update() end)

	local f = CreateFrame("Frame", "CovForge_WeightTotal", SoulbindViewer, "CovenantForge_WeightTotalTemplate")
	addon.CovForge_WeightTotalFrame = f
	f:Show()
	f:ClearAllPoints()
	f:SetPoint("BOTTOM",SoulbindViewer.ActivateSoulbindButton,"BOTTOM", 0, 25)

	addon:Hook(SoulbindViewer, "UpdateCommitConduitsButton", function()addon.CovForge_WeightTotalFrame:SetShown(not SoulbindViewer.CommitConduitsButton:IsShown()) end, true)
	--addon.CovForge_WeightTotalFrame:SetShown(not SoulbindViewer.CommitConduitsButton:IsShown())
	addon:Update()

	f = CreateFrame("Frame", "CovForge_PathStorage", SoulbindViewer, "CovenantForge_PathStorageTemplate")
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", SoulbindViewer.ConduitList, "TOPLEFT", 10, 0)
	f:SetPoint("BOTTOMRIGHT", SoulbindViewer.ConduitList, "BOTTOMRIGHT" , 10, -40)
	addon.PathStorageFrame = f
	f.Background:SetDesaturated(true)
	f.Background:SetAlpha(0.3)
	f.Background:SetAtlas(covenantBgAtlasIDs[covenantID], nil)
	f:Hide()

	addon.PathStorageFrame.TabList = {}
	local PathTab = CreateFrame("CheckButton", "$parentTab1", SoulbindViewer, "CovenantForge_TabTemplate", 1)
   -- PathTab:SetSize(50,50)
	PathTab:SetPoint("TOPRIGHT", SoulbindViewer, "TOPRIGHT", 30, -20)
	PathTab.tooltip = L["Saved Paths"]
	PathTab:Show()
	PathTab.TabardEmblem:SetTexture("Interface/ICONS/Ability_Druid_FocusedGrowth")
	PathTab.tabIndex = 1
	table.insert(addon.PathStorageFrame.TabList,PathTab )

	local ConduitTab = CreateFrame("CheckButton", "$parentTab2", SoulbindViewer, "CovenantForge_TabTemplate", 1)
   -- PathTab:SetSize(50,50)
	ConduitTab:SetPoint("TOPRIGHT", PathTab, "BOTTOMRIGHT", 0, -20)
	ConduitTab.tooltip = L["Avaiable Conduits"]
	ConduitTab:Show()
	ConduitTab.TabardEmblem:SetTexture("Interface/ICONS/Ability_Monk_EssenceFont")
	ConduitTab.tabIndex = 2
	table.insert(addon.PathStorageFrame.TabList,ConduitTab )

	local WeightsTab = CreateFrame("CheckButton", "$parentTab3", SoulbindViewer, "CovenantForge_TabTemplate", 1)
   -- PathTab:SetSize(50,50)
	WeightsTab:SetPoint("TOPRIGHT", ConduitTab, "BOTTOMRIGHT", 0, -20)
	WeightsTab.tooltip = L["Weights"]
	WeightsTab:Show()
	WeightsTab.TabardEmblem:SetTexture("Interface/ICONS/INV_Stone_WeightStone_06.blp")
	WeightsTab.tabIndex = 3
	table.insert(addon.PathStorageFrame.TabList,WeightsTab )

	scrollcontainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
	scrollcontainer.frame:SetParent(addon.PathStorageFrame)
	scrollcontainer:ClearAllPoints()
	scrollcontainer:SetPoint("TOPLEFT", addon.PathStorageFrame,"TOPLEFT", 0, -55)
	scrollcontainer:SetPoint("BOTTOMRIGHT", addon.PathStorageFrame,"BOTTOMRIGHT", -15,15)
	scrollcontainer:SetFullWidth(true)
	scrollcontainer:SetFullHeight(true) -- probably?
	scrollcontainer:SetLayout("Fill")

	f:SetScript("OnHide", function() scrollcontainer:ReleaseChildren() end)
	f:SetScript("OnShow", function() addon:UpdateSavedPathsList() end)

	addon:UpdateSavedPathsList()
end

local currentTab
function CovenantForgeSavedTab_OnClick(self)
	for i, tab in ipairs(addon.PathStorageFrame.TabList) do
	tab:SetChecked(false);
	end

	local index = self.tabIndex
	if currentTab == index then 
		addon.PathStorageFrame:Hide()
			SoulbindViewer.ConduitList:Show()

		self:SetChecked(false)
		currentTab = nil
	else
		addon.PathStorageFrame:Show()
			SoulbindViewer.ConduitList:Hide()

		self:SetChecked(true)
		currentTab = index
	end

	if index == 1 then
		addon.PathStorageFrame.EditBox:Show()
		addon.PathStorageFrame.CreateButton:Show()
		addon.PathStorageFrame.Title:SetText(L["Saved Paths"])
		addon:UpdateSavedPathsList()
	elseif index == 2 then
		addon.PathStorageFrame.EditBox:Hide()
		addon.PathStorageFrame.CreateButton:Hide()
		addon.PathStorageFrame.Title:SetText(L["Conduits"])
		addon:UpdateConduitList()
	elseif index == 3 then
		addon.PathStorageFrame.EditBox:Hide()
		addon.PathStorageFrame.CreateButton:Hide()
		addon.PathStorageFrame.Title:SetText(L["Weights"])
		addon:UpdateWeightList()
	end
end



function addon:UpdateSavedPathsList()
	if not addon.savedPathdb.char.paths then return end

	scrollcontainer:ReleaseChildren()
	scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow") -- probably?
	scrollcontainer:AddChild(scroll)

	for i, data in ipairs(addon.savedPathdb.char.paths) do
		local container = AceGUI:Create("SimpleGroup") 
		local InteractiveLabel = AceGUI:Create("InteractiveLabel")
		InteractiveLabel:SetText(data.name)
		InteractiveLabel:SetImage(data.icon)
		InteractiveLabel:SetImageSize(25,25)
		InteractiveLabel:SetHeight(30)
		--InteractiveLabel:SetWidth(225)
		InteractiveLabel:SetRelativeWidth(.9)
		InteractiveLabel:SetPoint("CENTER")
		InteractiveLabel:SetCallback("OnClick", function() addon:SelectPath(i) end)
		InteractiveLabel:SetCallback("OnEnter", function() addon:PathTooltip(InteractiveLabel, i) end)
		InteractiveLabel:SetCallback("OnLeave", function() GameTooltip:Hide() end)

		local UpdateButton =  AceGUI:Create("InteractiveLabel") 
		UpdateButton:SetImage("Interface/Buttons/UI-OptionsButton")
		UpdateButton:SetImageSize(15,15)
		UpdateButton:SetCallback("OnClick", function()
				if (not StaticPopup_Visible("COVENANTFORGE_UPDATEPOPUP")) then
				addon:ShowPopup("COVENANTFORGE_UPDATEPOPUP", i)
				end  end)
		UpdateButton:SetCallback("OnEnter", function() GameTooltip:SetOwner(UpdateButton.frame, "ANCHOR_RIGHT"); GameTooltip:AddLine(L["Options"]); GameTooltip:Show() end)
		UpdateButton:SetCallback("OnLeave", function() GameTooltip:Hide() end)
		UpdateButton:SetRelativeWidth(.1)
		UpdateButton.index = i

		container:AddChild(InteractiveLabel)
		container:AddChild(UpdateButton)
		container:SetLayout("Flow")
		container:SetFullWidth(true)
		container:SetHeight(40)
		scroll:AddChild(container)
	end
end


function addon:UpdateConduitList()
	scrollcontainer:ReleaseChildren()

	scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow") -- probably?
	scrollcontainer:AddChild(scroll)

	--local scrollframe = addon.ScrollFrame

	for i, typedata in pairs(conduitList) do
		local collectionData = C_Soulbinds.GetConduitCollection(i)


		local topHeading = AceGUI:Create("Heading") 
		topHeading:SetRelativeWidth(1)
		topHeading:SetHeight(5)
		local bottomHeading = AceGUI:Create("Heading") 
		bottomHeading:SetRelativeWidth(1)
		bottomHeading:SetHeight(5)

		local label = AceGUI:Create("Label") 
			label:SetText(Soulbinds.GetConduitName(i))
			local atlas = Soulbinds.GetConduitEmblemAtlas(i);
			--label:SetImage(icon)
			label:SetImage("Interface/Buttons/UI-OptionsButton")

			label.image:SetAtlas(atlas)
			label:SetFontObject(GameFontHighlightLarge)

			--label.image.imageshown = true
			label:SetImageSize(30,30)
			label:SetRelativeWidth(1)
			scroll:AddChild(topHeading)
			scroll:AddChild(label)
			scroll:AddChild(bottomHeading)

		for i, data in pairs(typedata) do
			local name = data[1]
			local type = Soulbinds.GetConduitName(data[3])
			local spellID = data[2]
			local desc = GetSpellDescription(spellID)
			local _,_, icon = GetSpellInfo(spellID)
			local titleColor = ORANGE_FONT_COLOR_CODE
			for i, data in ipairs(collectionData) do
				local c_spellID = C_Soulbinds.GetConduitSpellID(data.conduitID, data.conduitRank)
				if c_spellID == spellID then 
					titleColor = GREEN_FONT_COLOR_CODE
					break
				end
			end
			local weight = addon:GetWeightData(i, viewed_spec)
			if weight then
				if weight > 0 then
					if addon.Profile.ShowAsPercent then 
						weight = addon:GetWeightPercent(weight).."%"
					end
					weight = GREEN_FONT_COLOR_CODE.."(+"..weight..")"
				elseif weight < 0 then
					if addon.Profile.ShowAsPercent then 
						weight = addon:GetWeightPercent(weight).."%"
					end
					weight = RED_FONT_COLOR_CODE.."("..weight..")"
				else
					weight = ""
				end
			end

			local text = ("%s-%s (%s)-\n%s%s %s\n "):format(titleColor, name, type, GRAY_FONT_COLOR_CODE,desc,weight)
			local label = AceGUI:Create("Label") 
			label:SetText(text)
			label:SetImage(icon)
			label:SetFont("Fonts\\FRIZQT__.TTF", 12)
			label:SetImageSize(30,30)
			label:SetRelativeWidth(1)
			scroll:AddChild(label)
		end
	end
end


function addon:UpdateWeightList()
	scrollcontainer:ReleaseChildren()

	scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow") -- probably?
	scrollcontainer:AddChild(scroll)

	--local scrollframe = addon.ScrollFrame

	for i, typedata in pairs(conduitList) do
		local collectionData = C_Soulbinds.GetConduitCollection(i)


		local topHeading = AceGUI:Create("Heading") 
		topHeading:SetRelativeWidth(1)
		topHeading:SetHeight(5)
		local bottomHeading = AceGUI:Create("Heading") 
		bottomHeading:SetRelativeWidth(1)
		bottomHeading:SetHeight(5)

		local label = AceGUI:Create("Label") 
			label:SetText(Soulbinds.GetConduitName(i))
			local atlas = Soulbinds.GetConduitEmblemAtlas(i);
			--label:SetImage(icon)
			label:SetImage("Interface/Buttons/UI-OptionsButton")

			label.image:SetAtlas(atlas)
			label:SetFontObject(GameFontHighlightLarge)

			--label.image.imageshown = true
			label:SetImageSize(30,30)
			label:SetRelativeWidth(1)
			scroll:AddChild(topHeading)
			scroll:AddChild(label)
			scroll:AddChild(bottomHeading)

		for i, data in pairs(typedata) do
			local name = data[1]
			local type = Soulbinds.GetConduitName(data[3])
			local spellID = data[2]
			local desc = GetSpellDescription(spellID)
			local _,_, icon = GetSpellInfo(spellID)
			local titleColor = ORANGE_FONT_COLOR_CODE
			for i, data in ipairs(collectionData) do
				local c_spellID = C_Soulbinds.GetConduitSpellID(data.conduitID, data.conduitRank)
				if c_spellID == spellID then 
					titleColor = GREEN_FONT_COLOR_CODE
					break
				end
			end
			local weight = addon:GetWeightData(i, viewed_spec)
			if weight then
				if weight > 0 then
					if addon.Profile.ShowAsPercent then 
						weight = addon:GetWeightPercent(weight).."%"
					end
					weight = GREEN_FONT_COLOR_CODE.."(+"..weight..")"
				elseif weight < 0 then
					if addon.Profile.ShowAsPercent then 
						weight = addon:GetWeightPercent(weight).."%"
					end
					weight = RED_FONT_COLOR_CODE.."("..weight..")"
				else
					weight = ""
				end
			end

			local text = ("%s-%s (%s)-\n%s%s %s\n "):format(titleColor, name, type, GRAY_FONT_COLOR_CODE,desc,weight)
			local label = AceGUI:Create("Label") 
			label:SetText(text)
			label:SetImage(icon)
			label:SetFont("Fonts\\FRIZQT__.TTF", 12)
			label:SetImageSize(30,30)
			label:SetRelativeWidth(1)
			scroll:AddChild(label)
		end
	end
end


function addon:PathTooltip(parent, index)
	if not addon.savedPathdb.char.paths[index] then return end

	local data = addon.savedPathdb.char.paths[index]
	local covenantData = C_Covenants.GetCovenantData(data.covenantID)
	local soulbindData = C_Soulbinds.GetSoulbindData(data.soulbindID)
	local r,g,b = COVENANT_COLORS[data.covenantID]:GetRGB()

	GameTooltip:SetOwner(parent.frame, "ANCHOR_RIGHT")

	GameTooltip:AddLine(("%s - %s"):format(covenantData.name, soulbindData.name),r,g,b)
	GameTooltip:AddLine(" ")

	 local pathList = {}
		for k, v in pairs(data.data) do table.insert(pathList, v) end
		table.sort(pathList, function(a,b) return a.row < b.row end)

		for i, pathEntry in ipairs(pathList) do
			if pathEntry.conduitID > 0 then
				local collectionData = C_Soulbinds.GetConduitCollectionData(pathEntry.conduitID)
				local quality = C_Soulbinds.GetConduitQuality(collectionData.conduitID, collectionData.conduitRank)
				print(ITEM_QUALITY_COLORS[quality].color:GetRGB())


				local spellID = C_Soulbinds.GetConduitSpellID(collectionData.conduitID, collectionData.conduitRank)
				local name = GetSpellInfo(spellID)
				--local desc = GetSpellDescription(spellID)
				local colormarkup = DARKYELLOW_FONT_COLOR:GenerateHexColorMarkup()
				GameTooltip:AddLine(string.format(L[colormarkup.."Row%d: |r%s - Rank:%s |cffffffff(%s)|r"],i, name, collectionData.conduitRank,Soulbinds.GetConduitName(collectionData.conduitType)), unpack({ITEM_QUALITY_COLORS[quality].color:GetRGB()}))
				--GameTooltip:AddLine(string.format("Rank:%s", collectionData.conduitRank, unpack({ITEM_QUALITY_COLORS[quality].color:GetRGB()})))
				--GameTooltip:AddLine(desc, nil, nil, nil, true)
				--GameTooltip:AddLine(" ")
			  else
				local spellID = pathEntry.spellID
				local name = GetSpellInfo(spellID)
				local desc = GetSpellDescription(spellID)

				GameTooltip:AddLine(string.format("Row%d: |cffffffff%s|r", i, name))
			  --  GameTooltip:AddLine(string.format("Rank:%s", name, unpack({ITEM_QUALITY_COLORS[quality].color:GetRGB()})))
				--GameTooltip:AddLine(desc, nil, nil, nil, true)
				--GameTooltip:AddLine(" ")
			end
		end

	GameTooltip:Show()
end


function addon:GetPathData()
	local pathData = {}
	local icon, _
	for i, nodeFrame in pairs(SoulbindViewer.Tree:GetNodes()) do
			local node = nodeFrame.node
			--local nodeID = nodeFrame.node.ID
			--local conduitID = C_Soulbinds.GetInstalledConduitID(node.ID)

		if node.state == 3 and node.row ~=0 then 

				pathData[node.ID] = {
					state = node.state,
					icon = node.icon,
					row = node.row,
					conduitID = node.conduitID,
					spellID = node.spellID,

				}
			if node.row == 1 then 
				--if node.conduitID == 0 then
					icon = node.icon
				local spellID = C_Soulbinds.GetConduitSpellID(node.conduitID, node.conduitRank)
				_,_, icon = GetSpellInfo(spellID)

				--else
				--_, _, icon = GetSpellInfo(node.spellID)
				--end
			end
		end
		 

	end
	return pathData, icon
end


function addon:DeletePath(index)
	table.remove(addon.savedPathdb.char.paths, index)
	addon:UpdateSavedPathsList()
end


function addon:SelectPath(index)
	local pathData = addon.savedPathdb.char.paths[index]

	if not pathData then return end
	if not C_Soulbinds.CanSwitchActiveSoulbindTreeBranch() then
		print("Need Rest ARea")
		return
	end

	local covenantData = C_Covenants.GetCovenantData(pathData.covenantID)
	local soulbindIDs = covenantData.soulbindIDs
	local soulbindID = pathData.soulbindID

	local currentSoulbindId = SoulbindViewer:GetOpenSoulbindID()
	local currentSoulbindData = C_Soulbinds.GetSoulbindData(currentSoulbindId)

	-- Check if the selection would make any changes (so we can abort if not at the Forge of Bonds)
	if not C_Soulbinds.CanModifySoulbind() then
		for nodeID, pathEntry in pairs(pathData.data) do
			local currentNode = C_Soulbinds.GetNode(nodeID)

			-- If the conduit is different to the one saved, modify it
			if currentNode.conduitID ~= pathEntry.conduitID then
				print("NF")
				return
			end
		end
	end

	-- Reset any currently open souldbind changes
	for i, node in pairs(currentSoulbindData.tree.nodes) do
		if C_Soulbinds.IsNodePendingModify(node.ID) then
			C_Soulbinds.UnmodifyNode(node.ID)
			C_Soulbinds.UnmodifyNode(node.ID)
		end
	end

	-- Select the request soulbind if not currently viewing it
	if currentSoulbindId ~= soulbindID then
		SoulbindViewer.SelectGroup.buttonGroup:SelectAtIndex(tIndexOf(soulbindIDs, soulbindID))
	end

	-- Choose the nodes per the saved path
	for nodeID, pathEntry in pairs(pathData.data) do
		local currentNode = C_Soulbinds.GetNode(nodeID)

		-- if any existing changes for this node, cancel them
		if C_Soulbinds.IsNodePendingModify(nodeID) then
			C_Soulbinds.UnmodifyNode(nodeID)
			C_Soulbinds.UnmodifyNode(nodeID)
		end

		-- If the conduit is different to the one saved, modify it
		if currentNode.conduitID ~= pathEntry.conduitID then
			C_Soulbinds.ModifyNode(nodeID, pathEntry.conduitID, 0)
		end

		-- If the node saves was selected, select it too
		if pathEntry.state == 3 then
			C_Soulbinds.SelectNode(nodeID)
		end
	end

	-- Activate the Soulbind if not current
	if C_Soulbinds.GetActiveSoulbindID() ~= soulbindID then
		SoulbindViewer:OnActivateSoulbindClicked()
	end

	-- THIS AUTO ACCEPTS, PROBABLY A BAD IDEA TO USE IT...
	-- C_Soulbinds.CommitPendingConduitsInSoulbind(soulbindID)

	-- Prompt if there's any changes as a result of the new path/conduits
	--if SCMdb.settings.attemptApply and C_Soulbinds.HasAnyPendingConduits() then
		--SoulbindViewer:OnCommitConduitsClicked()
   -- end
	
end

--Updates Weight Values & Names
function addon:Update()
	local spec = GetSpecialization()
	local specID, specName = GetSpecializationInfo(spec)
	local curentsoulbindID = Soulbinds.GetOpenSoulbindID() or C_Soulbinds.GetActiveSoulbindID();


	for buttonIndex, button in ipairs(SoulbindViewer.SelectGroup.buttonGroup:GetButtons()) do
		local f = button.ForgeInfo 
		if not f then 
			f = CreateFrame("Frame", "CovForge_Souldbind"..buttonIndex, button, "CovenantForge_SoulbindInfoTemplate")
			button.ForgeInfo = f
		end

		local soulbindID = button:GetSoulbindID()
		f.soulbindName:SetText(C_Soulbinds.GetSoulbindData(soulbindID).name)
		local selectedTotal, unlockedTotal, nodeMax, conduitMax = addon:GetSoulbindWeight(soulbindID)
		--local nodeTotal, conduitTotal, selectedTotal, unlockedConduitTotal = addon:GetSoulbindWeight(soulbindID)
		--local totalValue = selectedNodeTotal + selectedConduitTotal
		f.soulbindWeight:SetText(selectedTotal .. "("..nodeMax+conduitMax..")" )

		if curentsoulbindID == soulbindID then 
			addon.CovForge_WeightTotalFrame.Weight:SetText(L["Current: %s/%s\nMax Possible: %s"]:format(selectedTotal, unlockedTotal ,nodeMax+conduitMax))
		end
	end

	for buttonIndex, nodeFrame in pairs(SoulbindViewer.Tree:GetNodes()) do
		local f = nodeFrame.ForgeInfo
		if not f then       
			f = CreateFrame("Frame", "CovForge_Conduit"..buttonIndex, nodeFrame, "CovenantForge_ConduitInfoTemplate")
			nodeFrame.ForgeInfo = f
		end
		f.Name:SetText("")
		if nodeFrame.Emblem then 
			nodeFrame.Emblem:ClearAllPoints()
			nodeFrame.Emblem:SetPoint("TOP", 0,16)
			nodeFrame.EmblemBg:ClearAllPoints()
			nodeFrame.EmblemBg:SetPoint("TOP", 0,16)
			f.Name:ClearAllPoints()
			f.Name:SetPoint("TOP",0, 21)
		end

		local name, weight
		if nodeFrame:IsConduit() then
			local conduit = nodeFrame:GetConduit()
			local conduitID = conduit:GetConduitID()
			if conduit and conduitID > 0  then
				local spellID = addon.Conduits[conduitID][2]
				local name = GetSpellInfo(spellID)
				local rank = conduit:GetConduitRank()
				local itemLevel = C_Soulbinds.GetConduitItemLevel(conduitID, rank)
				weight = addon:GetWeightData(conduitID, viewed_spec)
				f.Name:SetText(name)
			else
				f.Name:SetText("")
			end
		else
			local spellID =  nodeFrame.spell:GetSpellID()
			local name = GetSpellInfo(spellID) or ""
			f.Name:SetText(name)
			weight = addon:GetTalentWeight(spellID, viewed_spec)
		end

		if weight and weight ~= 0 then 
			local sign = "+"
			if weight > 0 then 
				f.Value:SetTextColor(0,1,0)
			elseif weight < 0 then 
				f.Value:SetTextColor(1,0,0)
				sign = ""

			end

			if addon.Profile.ShowAsPercent then 
				weight = sign..addon:GetWeightPercent(weight).."%"
			end

			f.Value:SetText(weight)
		else
			f.Value:SetText("")
		end
	end

	for conduitType, conduitData in ipairs(SoulbindViewer.ConduitList:GetLists()) do
		for conduitButton in SoulbindViewer.ConduitList.ScrollBox.ScrollTarget.Lists[conduitType].pool:EnumerateActive() do
			local conduitID = conduitButton.conduitData.conduitID
			local conduitItemLevel = conduitButton.conduitData.conduitItemLevel
			local conduitRank = conduitButton.conduitData.conduitRank

			local ilevelText = L["%s (Rank %d)"]:format(conduitItemLevel,conduitRank )
			local weight = addon:GetWeightData(conduitID, viewed_spec, itemLevel)
			local percent = addon:GetWeightPercent(weight)

			if weight ~=0 then 
				if addon.Profile.ShowAsPercent then 
					if percent > 0 then 
						conduitButton.ItemLevel:SetText(ilevelText..GREEN_FONT_COLOR_CODE.." (+"..percent.."%)");
					elseif percent < 0 then 
						conduitButton.ItemLevel:SetText(ilevelText..RED_FONT_COLOR_CODE.." ("..percent.."%)");
					end
				else
					if weight > 0 then 
						conduitButton.ItemLevel:SetText(ilevelText..GREEN_FONT_COLOR_CODE.." (+"..weight..")");
					elseif weight < 0 then 
						conduitButton.ItemLevel:SetText(ilevelText..RED_FONT_COLOR_CODE.." ("..weight..")");
					end
				end
			else 
				conduitButton.ItemLevel:SetText(ilevelText);
			end
		end
	end

	addon.CovForge_WeightTotalFrame:SetShown(not SoulbindViewer.CommitConduitsButton:IsShown())
	
	if addon.PathStorageFrame and addon.PathStorageFrame:IsShown() and currentTab == 2 then
		addon:UpdateConduitList()
	end
end

local Weights = {}
local ilevel = {}
function addon:BuildWeightData()
	local spec = GetSpecialization()
	local specID, specName = GetSpecializationInfo(spec)
	local _, _, classID = UnitClass("player")
	local covenantID = C_Covenants.GetActiveCovenantID();
	local classSpecs = CLASS_SPECS[classID]
	for i,spec in ipairs(classSpecs) do
		if addon.Weights["PR"][spec] then 
			local data = addon.Weights["PR"][spec][covenantID]
			Weights[spec] =  {}
			for i=2, #data do
				local conduitData = data[i]
				local name = string.gsub(conduitData[1],' %(.+%)',"")
				local ilevel ={}
				for index = 2, #conduitData do
					local ilevelData = data[1][index]
					ilevel[ilevelData] = conduitData[index]
				end
				Weights[spec][name] = ilevel
			end
		end

	end
end


function addon:GetWeightData(conduitID, specID)
	if not addon.Conduits[conduitID] or not Weights[specID] then return 0 end
	local soulbindName = addon.Conduits[conduitID][1]
	--if soulbindName == "Rejuvenating Wind" then return 31 end
	local collectionData  = C_Soulbinds.GetConduitCollectionData(conduitID)
	local conduitItemLevel = collectionData and collectionData.conduitItemLevel or 145

	if Weights[specID][soulbindName] then 
		local weight = Weights[specID][soulbindName][conduitItemLevel]
		return weight
	end

	return 0
end


function addon:GetTalentWeight(spellID, specID)
	--if spellID == 320658 then return 51 end
	if not addon.Soulbinds[spellID] or not Weights[specID] then return 0 end
	local name = addon.Soulbinds[spellID]
	if Weights[specID][name] then 
		local weight = Weights[specID][name][1]
		return weight
	end

	return 0
end


local function BuildTreeData(tree)
	local parentNodeTable = {}
	local parentNodeData = {}
	for i, data in ipairs(tree) do
		parentNodeData[data.ID] = data
		local parentNodeIDs = data.parentNodeIDs
		if #parentNodeIDs == 1  and data.row ~= 0 then 
			parentNodeTable[data.ID] = data.parentNodeIDs[1]
		--  print(data.parentNodeIDs[1])
		end
	end
	return parentNodeTable, parentNodeData
end


function addon:GetSoulbindWeight(soulbindID)
	local data = C_Soulbinds.GetSoulbindData(soulbindID)
	local tree = data.tree.nodes
	local parentNodeTable, parentNodeData = BuildTreeData(tree) 

	local selectedWeight = {}
	local unlockedWeights = {}
	local maxNodeWeights = {}
	local maxConduitWeights = {}
	local parentRow = {}

	for i, data in ipairs(tree) do
		local row = data.row  --RowID starts at 0
		local conduitID = data.conduitID
		local spellID = data.spellID
		local state = data.state
		local weight
		local maxTable
		local selectedTable
		local unlockedTable
		

		local parentNode = parentNodeTable[data.ID]
		local parentData = parentNodeData[parentNode]
		local parentWeight = 0
		
		
		if conduitID == 0 then
			weight = addon:GetTalentWeight(spellID, viewed_spec)

			maxTable = maxNodeWeights
		else
			weight = addon:GetWeightData(conduitID, viewed_spec)

			maxTable = maxConduitWeights
		end

		if parentData and parentData.conduitID == 0 then
				parentWeight = addon:GetTalentWeight(parentData.spellID, viewed_spec)
				parentRow[parentData.row] = true
		elseif parentData then 
			parentWeight = addon:GetWeightData(parentData.conduitID, viewed_spec)
			parentRow[parentData.row] = true
		end

		if weight and state == 3 then
			selectedWeight[row] = weight
		end

		unlockedWeights[row] = unlockedWeights[row] or 0
		if weight and state ~= 0 and  weight + parentWeight >= unlockedWeights[row] then
			unlockedWeights[row] = weight + parentWeight 
		end

		maxTable[row] = maxTable[row] or 0
		if weight and weight + parentWeight  >= maxTable[row] then
			maxTable[row] = weight + parentWeight 
		end
	end

	for i, data in pairs(parentRow)do
		if i ~=0 then 
			maxNodeWeights[i] = 0
			unlockedWeights[i] = 0
			maxConduitWeights[i] = 0
		end
	end

	local selectedTotal = 0
	for i, value in pairs(selectedWeight) do
		selectedTotal = selectedTotal + value
	end

	local unlockedTotal = 0
	for i, value in pairs(unlockedWeights) do
		unlockedTotal = unlockedTotal + value
	end


	local nodeMax = 0
	for i, value in pairs(maxNodeWeights) do
		nodeMax = nodeMax + value
	end


	local conduitMax = 0
	for i, value in pairs(maxConduitWeights) do
		conduitMax = conduitMax + value
	end

	return selectedTotal, unlockedTotal, nodeMax, conduitMax
end


function addon:GetWeightPercent(weight)
	local percent = weight/WEIGHT_BASE

	 --return percent>=0 and math.floor(percent+0.5) or math.ceil(percent-0.5)
 return  tonumber(string.format("%.2f", percent))
end


function addon:GenerateToolip(tooltip)
	--print("s")
	if not self.Profile.ShowTooltipRank then return end

	local name, itemLink = tooltip:GetItem()
	if not name then return end

	if C_Soulbinds.IsItemConduitByItemInfo(itemLink) then
		local itemLevel = select(4, GetItemInfo(itemLink))

		for rank, level in pairs(CONDUIT_RANKS) do
			if itemLevel == level then
				self:ConduitTooltip_Rank(tooltip, rank);
			end
		end
	end
end


local ItemLevelPattern = gsub(ITEM_LEVEL, "%%d", "(%%d+)")

function addon:ConduitTooltip_Rank(tooltip, rank)
	local text, level
	local textLeft = tooltip.textLeft
	if not textLeft then
		local tooltipName = tooltip:GetName()
		textLeft = setmetatable({}, { __index = function(t, i)
			local line = _G[tooltipName .. "TextLeft" .. i]
			t[i] = line
			return line
		end })
		tooltip.textLeft = textLeft
	end
	for i = 3, 5 do
		if _G[tooltip:GetName() .. "TextLeft" .. i] then
			local line = textLeft[i]
			text = _G[tooltip:GetName() .. "TextLeft" .. i]:GetText() or ""
			level = string.match(text, ItemLevelPattern)
			if (level) then
				line:SetFormattedText("%s (Rank %d)", text, rank);
				return ;
			end
		end
	end
end


function addon:StopAnimationFX(viewer)
	if self.Profile.disableFX then
		viewer.ForgeSheen.Anim:SetPlaying(false);
		viewer.BackgroundSheen1.Anim:SetPlaying(false);
		viewer.BackgroundSheen2.Anim:SetPlaying(false);
		viewer.GridSheen.Anim:SetPlaying(false);
		viewer.BackgroundRuneLeft.Anim:SetPlaying(false);
		viewer.BackgroundRuneRight.Anim:SetPlaying(false);
		viewer.ConduitList.Fx.ChargeSheen.Anim:SetPlaying(false);

		for buttonIndex, button in ipairs(SoulbindViewer.SelectGroup.buttonGroup:GetButtons()) do
			button.ModelScene.NewAlert:Hide();
			button.ModelScene.Highlight2.Pulse:Stop();
			button.ModelScene.Highlight3.Pulse:Stop();
			button.ModelScene.Dark.Pulse:Stop();
			button:GetFxModelScene():ClearEffects();
			button.ModelScene:SetPaused(true)
		end
	end
end


function addon:StopNodeFX(viewer)
	if self.Profile.disableFX then
		viewer.FlowAnim1:Stop();
		viewer.FlowAnim2:Stop();
		viewer.FlowAnim3:Stop();
		viewer.FlowAnim4:Stop();
		viewer.FlowAnim5:Stop();
		viewer.FlowAnim6:Stop();
	end
end

function addon:SavePath()
	local covenantID = C_Covenants.GetActiveCovenantID()
	local soulbindID = SoulbindViewer:GetOpenSoulbindID()
	local pathData, icon  = addon:GetPathData()

	local Path = {
		icon = icon,
		covenantID = covenantID,
		soulbindID =  soulbindID,
		data = pathData,    
	}

	return Path
end

CovenantForge_SavedPathMixin = {}
function CovenantForge_SavedPathMixin:OnClick()
   if string.len(self:GetParent().EditBox:GetText()) <= 0 then return end

	local Path = addon:SavePath()
	Path.name = self:GetParent().EditBox:GetText(),
	table.insert(addon.savedPathdb.char.paths, Path)
	addon:UpdateSavedPathsList()
end


function addon:GetConduits()
	local className, classFile, classID = UnitClass("player")
	local classSpecs = CLASS_SPECS[classID]
	

	for i, data in pairs(addon.Conduits) do
		local valid = false
		for i, spec in ipairs(classSpecs) do
			if valid then break end

			for i, con_spec in ipairs(data[4]) do
				if spec == con_spec then 
					valid = true
					break
				end
			end
		end

		if valid then 
			local type = data[3]
			conduitList[type] = conduitList[type] or {}
			conduitList[type][i] = data
		end

	end
end





--[[

	for i,spec in ipairs(classSpecs) do

	--addon.Weights["PR"][specID][covenantID]
end

end 

function addon:GetConduitInfo(name)
	for i, data in pairs(addon.Conduits) do
	addon.Conduits ={
	[5]={ "Stalwart Guardian", 334993, 2, {72,71,73,},},

end

	self.conduitData = conduitData;
	self.conduit = SoulbindConduitMixin_Create(conduitData.conduitID, conduitData.conduitRank);

	local itemID = conduitData.conduitItemID;
	local item = Item:CreateFromItemID(itemID);
	local itemCallback = function()
		self.ConduitName:SetSize(150, 30);
		self.ConduitName:SetText(item:GetItemName());
		self.ConduitName:SetHeight(self.ConduitName:GetStringHeight());
		
		local yOffset = self.ConduitName:GetNumLines() > 1 and -6 or 0;
		self.ConduitName:ClearAllPoints();
		self.ConduitName:SetPoint("BOTTOMLEFT", self.Icon, "RIGHT", 10, yOffset);
		self.ConduitName:SetWidth(150);

		self.ItemLevel:SetPoint("TOPLEFT", self.ConduitName, "BOTTOMLEFT", 0, 0);
		self.ItemLevel:SetText(conduitData.conduitItemLevel);



]]

function addon:ShowPopup(popup, index)
	StaticPopupSpecial_Show(CovenantForge_SavedPathEditFrame)
	local data = addon.savedPathdb.char.paths[index]
	CovenantForge_SavedPathEditFrame.EditBox:SetText(data.name)
	CovenantForge_SavedPathEditFrame.pathIndex = index

		--StaticPopup_Show(popup, ...)

end


function addon:ClosePopups()
	StaticPopupSpecial_Hide(CovenantForge_SavedPathEditFrame)
end


CovenantForge_SavedPathEditFrameMixin = {}
function CovenantForge_SavedPathEditFrameMixin:OnDelete()
	addon:DeletePath(self.pathIndex)
	addon:ClosePopups()
end


function CovenantForge_SavedPathEditFrameMixin:OnAccept()
	local data = addon.savedPathdb.char.paths[self.pathIndex]
	data.name = CovenantForge_SavedPathEditFrame.EditBox:GetText()
	addon:UpdateSavedPathsList()
	addon:ClosePopups()
end


function CovenantForge_SavedPathEditFrameMixin:OnUpdate()
	local name = addon.savedPathdb.char.paths[self.pathIndex].name
	addon.savedPathdb.char.paths[self.pathIndex] = addon:SavePath()
	addon.savedPathdb.char.paths[self.pathIndex].name = name
	addon:UpdateSavedPathsList()
	addon:ClosePopups()
end