--  ///////////////////////////////////////////////////////////////////////////////////////////
--
--   
--  Author: SLOKnightfall

--  

--

--  ///////////////////////////////////////////////////////////////////////////////////////////

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

local playerInv_DB
local Profile
local playerNme
local realmName
local playerClass, classID,_
local conduitList = {}

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local AceGUI = LibStub("AceGUI-3.0")

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


local WEIGHT_BASE = 37.75
local CLASS_SPECS ={{71,72,73},{65,66,70},{253,254,255},{259,260,261},{256,257,258},{250,251,252},{262,263,264},{62,63,64},{265,266,267},{268,270,269},{102,103,104,105},{577,578}}

local WeightProfiles = {}
local ProfileTable = {}
local Weights = {}
local BaseValue = {}
local ilevels = {}
local ilevelData = {}
local powers = {}


local function GetSoulbindPowers()
	local covenantData = C_Covenants.GetCovenantData(C_Covenants.GetActiveCovenantID())
	local soulbinds = covenantData.soulbindIDs
	for _, soulbindID in pairs(soulbinds) do
		local soulbindData = C_Soulbinds.GetSoulbindData(soulbindID)
		local tree = soulbindData.tree.nodes
		local soulbindPowers = {}
		for index, data in ipairs(tree) do
			if data.conduitID == 0 and data.spellID ~= 0 then 
				--if data.spellID == 0 then print(index) end
				table.insert(soulbindPowers, data.spellID)
			end
		end
		powers[soulbindID] = soulbindPowers
	end

	addon.powers = powers
end


local function SelectProfile(index)
	if not WeightProfiles[index] then  SelectProfile(1) end
	Weights = WeightProfiles[index].weights
	BaseValue = WeightProfiles[index].base
	addon.savedPathdb.char.selectedProfile = index
	addon:UpdateWeightList()
end


local defaultindex = 0
function addon:BuildWeightData()
	wipe(WeightProfiles)
	wipe(ProfileTable)
	defaultindex = 0
	GetSoulbindPowers()
	local spec = GetSpecialization()
	local specID, specName = GetSpecializationInfo(spec)
	local _, _, classID = UnitClass("player")
	local covenantID = C_Covenants.GetActiveCovenantID();
	local classSpecs = CLASS_SPECS[classID]
	for profile, weightData in pairs(addon.Weights) do
		local Weights = {}
		local baseValue = {} 
		for i,spec in ipairs(classSpecs) do
			if addon.Weights[profile][spec] then 
				local data = addon.Weights[profile][spec][covenantID]
				Weights[spec] =  {}
				for i=2, #data do
					local conduitData = data[i]
					local name = string.gsub(conduitData[1],' %(.+%)',"")
					local ilevel ={}
					for index = 2, #conduitData do
						local ilevelData = data[1][index]
						ilevels[index - 1 ] = ilevelData
						ilevel[ilevelData] = conduitData[index]
					end
					Weights[spec][name] = ilevel
					baseValue[spec] = addon.BaseValues[profile][spec][covenantID]
				end
			end
		end
		table.insert(WeightProfiles, {["name"] = profile, ["weights"]= Weights, ["base"] = baseValue })
		table.insert(ProfileTable, L[profile])
		defaultindex = defaultindex + 1
	end

	local profileList = self.weightdb.class.weights or {}
	for profile, weightData in pairs(profileList) do
		local baseValue = self.weightdb.class.base[profile]
		table.insert(WeightProfiles, {["name"] = profile, ["weights"]= weightData, ["base"] = baseValue})
		table.insert(ProfileTable, profile)
	end

	local selectedProfile = addon.savedPathdb.char.selectedProfile
	SelectProfile(selectedProfile)
end


function addon:GetConduitWeight(specID, conduitID)
	local profile = addon.savedPathdb.char.selectedProfile
	if not addon.Conduits[conduitID] or not Weights[specID] then return 0 end
	local soulbindName = addon.Conduits[conduitID][1]
	--if soulbindName == "Rejuvenating Wind" then return 31 end
	local collectionData  = C_Soulbinds.GetConduitCollectionData(conduitID)
	local conduitItemLevel = collectionData and collectionData.conduitItemLevel or 145

	if Weights[specID][soulbindName] then 
		local weight = Weights[specID][soulbindName][conduitItemLevel]
		return weight or 0
	end

	return 0
end


function addon:GetTalentWeight(specID, spellID)
	--if spellID == 320658 then return 51 end
	if not addon.Soulbinds[spellID] or not Weights[specID] then return 0 end

	local name = addon.Soulbinds[spellID]
	if Weights[specID][name] then 
		local weight = Weights[specID][name][1]
		return weight or 0
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

		local parentNode = parentNodeTable[data.ID]
		local parentData = parentNodeData[parentNode]
		local parentWeight = 0
		
		if conduitID == 0 then
			weight = addon:GetTalentWeight(addon.viewed_spec, spellID)

			maxTable = maxNodeWeights
		else
			weight = addon:GetConduitWeight(addon.viewed_spec, conduitID)

			maxTable = maxConduitWeights
		end

		if parentData and parentData.conduitID == 0 then
				parentWeight = addon:GetTalentWeight(addon.viewed_spec, parentData.spellID) or 0
				parentRow[parentData.row] = true
		elseif parentData then 
			parentWeight = addon:GetConduitWeight(addon.viewed_spec, parentData.conduitID) or 0
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
	if not weight then return 0 end
	--local percent = weight/WEIGHT_BASE
	BaseValue[addon.viewed_spec] = BaseValue[addon.viewed_spec] or 100
	local templateDPS = BaseValue[addon.viewed_spec]
	local formula = 100 * ((templateDPS + weight) / templateDPS - 1)
	return  tonumber(string.format("%.2f", formula))
end


local function CreateNewWeightProfile(name)
	local profileList = addon.weightdb.class.weights
	local baseValue = addon.weightdb.class.base
	local _, _, classID = UnitClass("player")
	local covenantID = C_Covenants.GetActiveCovenantID();
	local classSpecs = CLASS_SPECS[classID]
	if not profileList[name] then 
		profileList[name] = {}
		baseValue[name] = {}
		for _, specID in ipairs(classSpecs) do
			profileList[name][specID] = {{},{},{}}
			baseValue[name][specID] = 100
		end
	end
	addon:BuildWeightData()
	addon:UpdateWeightList()
end


local function CopyWeightProfile(name)
	local profileList = addon.weightdb.class.weights
	local baseValue = addon.weightdb.class.base
	local selectedProfile = addon.savedPathdb.char.selectedProfile
	local selectedName = WeightProfiles[selectedProfile].name
	local weights = CopyTable(Weights)
	local base = CopyTable(BaseValue)
	profileList[name] = weights

	table.insert(WeightProfiles, {["name"] = name, ["weights"]= weights, ["base"] = base })
	table.insert(ProfileTable, name)
	addon:UpdateWeightList()
end


local function DeleteWeightProfile(name)
	local profileList = addon.weightdb.class.weights
	local baseValue = addon.weightdb.class.base
	profileList[name] = nil
	baseValue[name] = nil
	SelectProfile(1)
	addon:BuildWeightData()
	addon:UpdateWeightList()
	addon.Update()
end


local function UpdateWeightData(name, ilevel, value)
--Weights[specID][name]
	Weights[tonumber(addon.viewed_spec)] = Weights[tonumber(addon.viewed_spec)] or {}
	Weights[tonumber(addon.viewed_spec)][name] = Weights[tonumber(addon.viewed_spec)][name] or {}
	Weights[tonumber(addon.viewed_spec)][name][tonumber(ilevel)] = tonumber(value)
	addon:UpdateWeightList()
	addon.Update()
end

local function UpdatePercentData(value)
	BaseValue[tonumber(addon.viewed_spec)] = tonumber(value)
	addon:UpdateWeightList()
	addon.Update()
end


local filterValue = 1
local filteredList = addon.conduitList
function addon:UpdateWeightList()
	if not SoulbindViewer or (SoulbindViewer and not SoulbindViewer:IsShown()) or
 		not addon.scrollcontainer then return end	

 	local filter = {L["All"], 	Soulbinds.GetConduitName(0),Soulbinds.GetConduitName(1),Soulbinds.GetConduitName(2), L["Soulbinds"]}
	local scrollcontainer = addon.scrollcontainer
	scrollcontainer:ReleaseChildren()
	scrollcontainer:SetPoint("TOPLEFT", addon.PathStorageFrame,"TOPLEFT", 0, -25)

	local selectedProfile = addon.savedPathdb.char.selectedProfile
	local weights = WeightProfiles[selectedProfile].weights
	local baseValue = WeightProfiles[selectedProfile].base

	scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow") -- probably?
	scrollcontainer:AddChild(scroll)

	local dropdown = AceGUI:Create("Dropdown")
	dropdown:SetFullWidth(false)
	dropdown:SetWidth(200)
	scroll:AddChild(dropdown)
	dropdown:SetList(ProfileTable)
	dropdown:SetValue(selectedProfile)
	dropdown:SetCallback("OnValueChanged", 
		function(self,event, key) 
			SelectProfile(key)
			addon:Update()
		end)


	local icon = AceGUI:Create("Icon") 
	icon:SetImage("Interface/Buttons/UI-OptionsButton")
	icon:SetHeight(20)
	icon:SetWidth(25)
	icon:SetImageSize(20,20)
	icon:SetCallback("OnClick", function() addon:OpenBarDropDown(icon.frame) end)

	scroll:AddChild(icon)

	dropdown = AceGUI:Create("Dropdown")
	dropdown:SetFullWidth(false)
	dropdown:SetWidth(125)
	dropdown:SetList(filter)
	dropdown:SetValue(filterValue)
	dropdown:SetCallback("OnValueChanged", 
		function(self,event, key) 
			filterValue = key; 
			if key == 1 then 
				filteredList = addon.conduitList
			else 
				filteredList = {addon.conduitList[key-2]}
			end
			addon:UpdateWeightList()
		end)
	scroll:AddChild(dropdown)

	local editbox = AceGUI:Create("EditBox")
	editbox:SetLabel(L["Percent Value"])
	editbox:SetWidth(80)
	editbox:SetHeight(40)
	editbox.editbox:SetTextInsets(0,-5, 0, 0)
	editbox.button:ClearAllPoints()
	editbox.button:SetPoint("LEFT", editbox.frame, "RIGHT", 0 , -8)
	editbox:SetDisabled(addon.savedPathdb.char.selectedProfile <= defaultindex)
	editbox:SetCallback("OnEnterPressed", function(self,event, key) 
		UpdatePercentData(key)
	end)

	local basedata = (baseValue[addon.viewed_spec])
	if basedata then 
		editbox:SetText(basedata)
	end
	scroll:AddChild(editbox)

	for i, typedata in pairs(filteredList) do
		local index = i
		if #filteredList == 1 then 
			index = filterValue - 2
		end
		local collectionData = C_Soulbinds.GetConduitCollection(index)

		local topHeading = AceGUI:Create("Heading") 
		topHeading:SetRelativeWidth(1)
		topHeading:SetHeight(5)
		local bottomHeading = AceGUI:Create("Heading") 
		bottomHeading:SetRelativeWidth(1)
		bottomHeading:SetHeight(5)

		local label = AceGUI:Create("Label") 
			label:SetText(Soulbinds.GetConduitName(index))
			--Bit of a hack as Ace doesn't have a set atlas function. 
			local atlas = Soulbinds.GetConduitEmblemAtlas(index);
			--Sets a base image to trigger ACE stuff
			label:SetImage("Interface/Buttons/UI-OptionsButton")
			--Manually sets the image frame to atlas value
			label.image:SetAtlas(atlas)
			label:SetFontObject(GameFontHighlightLarge)
			label:SetImageSize(30,30)
			label:SetRelativeWidth(1)
			scroll:AddChild(topHeading)
			scroll:AddChild(label)

		for i, data in pairs(typedata) do
			local spellID = data[2]
			local name = GetSpellInfo(spellID) or data[1]
			local type = Soulbinds.GetConduitName(data[3])
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
			
			local container = AceGUI:Create("SimpleGroup") 
			container:SetLayout("Flow")
			container:SetFullWidth(true)
			container:SetHeight(20)

			local text = ("%s-%s (%s)-"):format(titleColor, name, type, GRAY_FONT_COLOR_CODE,desc,weight)
			local Icon = AceGUI:Create("Label") 
			Icon:SetText(text)
			Icon:SetImage(icon)
			--icon:SetFont("Fonts\\FRIZQT__.TTF", 12)
			Icon:SetImageSize(20,20)
			Icon:SetFullWidth(true)
			Icon:SetHeight(20)
			--icon:SetRelativeWidth(1)
			container:AddChild(Icon)


			local ileveldata = (weights[addon.viewed_spec] and weights[addon.viewed_spec][name])
			for i, data in pairs(ilevels) do
				if i ~= 1 then 
					local editbox = AceGUI:Create("EditBox")
					editbox:SetLabel(data)
					editbox:SetWidth(50)
					editbox:SetHeight(40)
					editbox.editbox:SetTextInsets(0,-5, 0, 0)
					editbox.button:ClearAllPoints()
					editbox.button:SetPoint("LEFT", editbox.frame, "RIGHT", 0 , -8)
					editbox:SetDisabled(addon.savedPathdb.char.selectedProfile <= defaultindex)
					editbox:SetCallback("OnEnterPressed", function(self,event, key) 
						UpdateWeightData(name, data, key)
					end)

					if ileveldata then 
						editbox:SetText(ileveldata[data] or 0)
					end
					container:AddChild(editbox)
				end
			end
			local topHeading = AceGUI:Create("Heading") 
			topHeading:SetRelativeWidth(1)
			topHeading:SetHeight(5)
			scroll:AddChild(topHeading)
			scroll:AddChild(container)
		end
	end
	if filterValue == 1 or filterValue == 5 then 
		local topHeading = AceGUI:Create("Heading") 
		topHeading:SetRelativeWidth(1)
		topHeading:SetHeight(5)

		local label = AceGUI:Create("Label") 
		label:SetText(L["Soulbinds"])

		local covenantData = C_Covenants.GetCovenantData(C_Covenants.GetActiveCovenantID())
		label:SetImage("Interface/Buttons/UI-OptionsButton")
		label.image:SetAtlas(("CovenantChoice-Celebration-%sSigil"):format(covenantData.textureKit))

		label:SetFontObject(GameFontHighlightLarge)

		--label.image.imageshown = true
		label:SetImageSize(30,30)
		label:SetRelativeWidth(1)
		label:SetHeight(5)
		scroll:AddChild(topHeading)
		scroll:AddChild(label)
		for soulbindID, sb_powers in pairs(powers) do
			local soulbind_data = C_Soulbinds.GetSoulbindData(soulbindID)
			for i, spellID in pairs(sb_powers) do
				local spellname = GetSpellInfo(spellID)
				local name = soulbind_data.name..": "..spellname or ""
				local desc = GetSpellDescription(spellID)
				local _,_, icon = GetSpellInfo(spellID)
				local titleColor = ORANGE_FONT_COLOR_CODE
				local container = AceGUI:Create("SimpleGroup") 
				container:SetLayout("Flow")
				container:SetFullWidth(true)
				container:SetHeight(20)

				local text = ("%s-%s-"):format(titleColor, name)
				local Icon = AceGUI:Create("Label") 
				Icon:SetText(text)
				Icon:SetImage(icon)
				--icon:SetFont("Fonts\\FRIZQT__.TTF", 12)
				Icon:SetImageSize(20,20)
				Icon:SetFullWidth(true)
				Icon:SetHeight(20)
				--icon:SetRelativeWidth(1)
				container:AddChild(Icon)
					--scroll:AddChild(container)

				local ileveldata = (weights[addon.viewed_spec] and  weights[addon.viewed_spec][spellname])

				local editbox = AceGUI:Create("EditBox")
				--editbox:SetLabel(data)
				editbox:SetWidth(50)
				editbox:SetHeight(40)
				editbox.button:ClearAllPoints()
				editbox.button:SetPoint("LEFT", editbox.frame, "RIGHT", 0 , -8)
				editbox:SetDisabled(addon.savedPathdb.char.selectedProfile <= defaultindex)
					editbox:SetCallback("OnEnterPressed", function(self,event, key) 
						UpdateWeightData(spellname, 1, key)
					end)

				if ileveldata then 
					editbox:SetText(ileveldata[1] or 0)
				end
				container:AddChild(editbox)
		
				local topHeading = AceGUI:Create("Heading") 
				topHeading:SetRelativeWidth(1)
				topHeading:SetHeight(5)
				scroll:AddChild(topHeading)
				scroll:AddChild(container)
			end
		end
	end
end


local function Faded(self)
	self:Release()
end

local function FadeMenu(self)
	local fadeInfo = {}
	fadeInfo.mode = "OUT"
	fadeInfo.timeToFade = 0.1
	fadeInfo.finishedFunc = Faded
	fadeInfo.finishedArg1 = self
	UIFrameFade(self, fadeInfo)
end

local LD = LibStub("LibDropdown-1.0")
local action
function addon:OpenBarDropDown(myframe, index)
	-- adopted from BulkMail
	-- release if if already shown
	local barmenuframe
	barmenuframe = barmenuframe and barmenuframe:Release()
	local baropts = {
		type = 'group',
		args = {
			details = {
				order = 10,
				name = L["Create New Blank Profile"],
				type = "execute",
				func = function(name)
						action = CreateNewWeightProfile
						if (not StaticPopup_Visible("COVENANTFORGE_UPDATEWEIGHTPOPUP")) then
							addon:ShowPopup("COVENANTFORGE_UPDATEWEIGHTPOPUP", i)
						end
						FadeMenu(barmenuframe)

				end,
			},
			graph = {
				order = 20,
				name = L["Copy Current Profile"],
				type = "execute",
				func = function(name)
					action = CopyWeightProfile
					if (not StaticPopup_Visible("COVENANTFORGE_UPDATEWEIGHTPOPUP")) then
						addon:ShowPopup("COVENANTFORGE_UPDATEWEIGHTPOPUP", i)
					end
						FadeMenu(barmenuframe)
				end,
			},
			addgraph = {
				order = 30,
				name = L["Delete Current Profile"],
				type = "execute",
				func = function(name)
					DeleteWeightProfile(ProfileTable[addon.savedPathdb.char.selectedProfile])
					FadeMenu(barmenuframe)

				end,
				disabled = function() return addon.savedPathdb.char.selectedProfile <= defaultindex end
				--me.AddCombatantToGraphWrapper,
			},
		}
	}

	barmenuframe = barmenuframe or LD:OpenAce3Menu(baropts)
	barmenuframe:SetClampedToScreen(true)
	barmenuframe:SetAlpha(1.0)
	barmenuframe:Show()

	local leftPos = myframe:GetLeft() -- Elsia: Side code adapted from Mirror
	local rightPos = myframe:GetRight()
	local side
	local oside
	if not rightPos then
		rightPos = 0
	end
	if not leftPos then
		leftPos = 0
	end

	local rightDist = GetScreenWidth() - rightPos

	if leftPos and rightDist < leftPos then
		side = "TOPLEFT"
		oside = "TOPRIGHT"
	else
		side = "TOPRIGHT"
		oside = "TOPLEFT"
	end

	barmenuframe:ClearAllPoints()
	barmenuframe:SetPoint(oside, myframe, side, 0, 0)
	--barmenuframe:SetFrameLevel(myframe:GetFrameLevel() + 9)
end


CovenantForge_WeightsEditFrameMixin = {}

function CovenantForge_WeightsEditFrameMixin:OnAccept()
local text = self.EditBox:GetText()
--print(text)
action(text)
action = nil
addon:ClosePopups()
end
