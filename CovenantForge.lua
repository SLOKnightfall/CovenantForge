--	///////////////////////////////////////////////////////////////////////////////////////////
--
--	 
--	Author: SLOKnightfall

--	

--

--	///////////////////////////////////////////////////////////////////////////////////////////

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
local Profile

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

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
					order = 1.2,
					name = L["Show Soulbind Name"],
					type = "toggle",
					width = 1.3,
					arg = "ShowSoulbindNames",
				},

				ShowNodeNames = {
					order = 1.2,
					name = L["Show Node Ability Names"],
					type = "toggle",
					width = 1.3,
					arg = "ShowNodeNames",
				},

				ShowAsPercent = {
					order = 1.2,
					name = L["Show Weight as Percent"],
					type = "toggle",
					width = 1.3,
					arg = "ShowAsPercent",
				},
			},
		},
	},

}

local defaults = {
	profile = {
				['*'] = true,
			},
}


---Ace based addon initilization
function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("CovenantForgeDB", defaults, true)
	addon.Profile = self.db.profile
	options.args.profiles  = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(options, addonName)
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("CovenantForge", "CovenantForge")
	--self.db.RegisterCallback(OmegaMap, "OnProfileChanged", "RefreshConfig")
	--self.db.RegisterCallback(OmegaMap, "OnProfileCopied", "RefreshConfig")
	--self.db.RegisterCallback(OmegaMap, "OnProfileReset", "RefreshConfig")



	addon:RegisterEvent("ADDON_LOADED", "EventHandler" )

end

function addon:EventHandler(event, arg1 )
	if event == "ADDON_LOADED" and arg1 == "Blizzard_Soulbinds" then 
		addon:Hook(SoulbindViewer, "Open", function()  C_Timer.After(.05, function() addon:Update() end) end , true)
		C_Timer.After(.05, function() addon.Init:CreateSoulbindFrames() end)
		addon:UnregisterEvent("ADDON_LOADED")
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
	local spec = GetSpecialization()
	viewed_spec = GetSpecializationInfo(spec)
end

local CLASS_SPECS ={{71,72,73},{65,66,70},{253,254,255},{259,260,261},{256,257,258},{250,251,252},{262,263,264},{62,63,64},{265,266,267},{268,269,270},{102,103,104,105},{577,578}}

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
		--local soulbindID = button:GetSoulbindID()
		--f.soulbindName:SetText(C_Soulbinds.GetSoulbindData(soulbindID).name)
		--local nodeTotal, conduitTotal = addon:GetSoulbindWeight(soulbindID)
		--f.soulbindWeight:SetText(nodeTotal + conduitTotal .. "["..nodeTotal.."]" )
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
end


--Updates Weight Values & Names
function addon:Update()
	local spec = GetSpecialization()
	local specID, specName = GetSpecializationInfo(spec)
	local curentsoulbindID = Soulbinds.GetOpenSoulbindID() or C_Soulbinds.GetActiveSoulbindID();


	for buttonIndex, button in ipairs(SoulbindViewer.SelectGroup.buttonGroup:GetButtons()) do
		local f = button.ForgeInfo
		local soulbindID = button:GetSoulbindID()
		f.soulbindName:SetText(C_Soulbinds.GetSoulbindData(soulbindID).name)
		local selectedTotal, unlockedTotal, nodeMax, conduitMax = addon:GetSoulbindWeight(soulbindID)
		--local nodeTotal, conduitTotal, selectedTotal, unlockedConduitTotal = addon:GetSoulbindWeight(soulbindID)
		--local totalValue = selectedNodeTotal + selectedConduitTotal
		f.soulbindWeight:SetText(selectedTotal .. "("..nodeMax+conduitMax..")" )

		if curentsoulbindID == soulbindID then 
			--addon.CovForge_WeightTotalFrame.Weight:SetText(L["Base: %s/%s\nCurrent: %s/%s"]:format(unlockedMax, nodeMax, selectedNodeTotal + selectedConduitTotal, conduitMax + unlockedMax))
		
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
			conduitButton.ItemLevel:SetText(conduitItemLevel);
			local conduitID = conduitButton.conduitData.conduitID
			local conduitItemLevel = conduitButton.conduitData.conduitItemLevel
			local weight = addon:GetWeightData(conduitID, viewed_spec, itemLevel)
			local percent = addon:GetWeightPercent(weight)

			if weight ~=0 then 
				if addon.Profile.ShowAsPercent then 
					if percent > 0 then 
						conduitButton.ItemLevel:SetText(conduitItemLevel..GREEN_FONT_COLOR_CODE.." (+"..percent.."%)");
					elseif percent < 0 then 
						conduitButton.ItemLevel:SetText(conduitItemLevel..RED_FONT_COLOR_CODE.." ("..percent.."%)");
					end
				else
					if weight > 0 then 
						conduitButton.ItemLevel:SetText(conduitItemLevel..GREEN_FONT_COLOR_CODE.." (+"..weight..")");
					elseif weight < 0 then 
						conduitButton.ItemLevel:SetText(conduitItemLevel..RED_FONT_COLOR_CODE.." ("..weight..")");
					end
				end
			else 
				conduitButton.ItemLevel:SetText(conduitItemLevel);
			end
		end
	end

	addon.CovForge_WeightTotalFrame:SetShown(not SoulbindViewer.CommitConduitsButton:IsShown())
end


local Weights = {}
local ilevel = {}

function addon:BuildWeightData()
	local spec = GetSpecialization()
	local specID, specName = GetSpecializationInfo(spec)
	local _, _, classID = UnitClass("player")
	local covenantID = C_Covenants.GetActiveCovenantID();
	local classSpecs = CLASS_SPECS[classID]
	if addon.Weights["PR"][specID] then 
		for i,spec in ipairs(classSpecs) do
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
	local conduitItemLevel = collectionData.conduitItemLevel

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
		--	print(data.parentNodeIDs[1])
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
--[[
	local spec = GetSpecialization()
	local specID, specName = GetSpecializationInfo(spec)
	local className, classFile, classID = UnitClass("player")
	local covenantID = C_Covenants.GetActiveCovenantID();
	local classSpecs = specID[classID]
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

