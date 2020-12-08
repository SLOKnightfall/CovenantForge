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


local WEIGHT_BASE = 37.75
local CLASS_SPECS ={{71,72,73},{65,66,70},{253,254,255},{259,260,261},{256,257,258},{250,251,252},{262,263,264},{62,63,64},{265,266,267},{268,269,270},{102,103,104,105},{577,578}}

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