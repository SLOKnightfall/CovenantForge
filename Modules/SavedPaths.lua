--  ///////////////////////////////////////////////////////////////////////////////////////////
--
--   
--  Author: SLOKnightfall

--  

--

--  ///////////////////////////////////////////////////////////////////////////////////////////

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local AceGUI = LibStub("AceGUI-3.0")

local playerInv_DB
local Profile
local playerNme
local realmName
local playerClass, classID,_
local viewed_spec
local conduitList = {}

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

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
				local spellID = C_Soulbinds.GetConduitSpellID(collectionData.conduitID, collectionData.conduitRank)
				local name = GetSpellInfo(spellID)
				--local desc = GetSpellDescription(spellID)
				local colormarkup = DARKYELLOW_FONT_COLOR:GenerateHexColorMarkup()
				GameTooltip:AddLine(string.format(L[colormarkup.."Row %d: |r%s - Rank:%s |cffffffff(%s)|r"],i, name, collectionData.conduitRank,Soulbinds.GetConduitName(collectionData.conduitType)), unpack({ITEM_QUALITY_COLORS[quality].color:GetRGB()}))
				--GameTooltip:AddLine(string.format("Rank:%s", collectionData.conduitRank, unpack({ITEM_QUALITY_COLORS[quality].color:GetRGB()})))
				--GameTooltip:AddLine(desc, nil, nil, nil, true)
				--GameTooltip:AddLine(" ")
			else
				local spellID = pathEntry.spellID
				local name = GetSpellInfo(spellID)
				local desc = GetSpellDescription(spellID)

				GameTooltip:AddLine(string.format("Row %d: |cffffffff%s|r", i, name))
			  --  GameTooltip:AddLine(string.format("Rank:%s", name, unpack({ITEM_QUALITY_COLORS[quality].color:GetRGB()})))
				--GameTooltip:AddLine(desc, nil, nil, nil, true)
				--GameTooltip:AddLine(" ")
			end
		end
	GameTooltip:Show()
end


local function GetPathData()
	local pathData = {}
	local icon, _
	for i, nodeFrame in pairs(SoulbindViewer.Tree:GetNodes()) do
		local node = nodeFrame.node
		if node.state == 3 then 
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



--Saved Path Popup Menu

function addon:ShowPopup(popup, index)
	StaticPopupSpecial_Show(CovenantForge_SavedPathEditFrame)
	local data = addon.savedPathdb.char.paths[index]
	CovenantForge_SavedPathEditFrame.EditBox:SetText(data.name)
	CovenantForge_SavedPathEditFrame.pathIndex = index
end


function addon:ClosePopups()
	StaticPopupSpecial_Hide(CovenantForge_SavedPathEditFrame)
end


CovenantForge_SavedPathEditFrameMixin = {}
function CovenantForge_SavedPathEditFrameMixin:OnDelete()
	addon:DeletePath(self.pathIndex)
	addon:ClosePopups()
end


local function CheckNames(name)
	if string.len(name) <= 0 then return false end

	for i, data in ipairs(addon.savedPathdb.char.paths) do
		if name == data.name then 
			return false
		end
	end
	return true
end


function CovenantForge_SavedPathEditFrameMixin:OnAccept()
	local data = addon.savedPathdb.char.paths[self.pathIndex]
	local name = CovenantForge_SavedPathEditFrame.EditBox:GetText()
	if CheckNames(name) then 
		data.name = CovenantForge_SavedPathEditFrame.EditBox:GetText()
		addon:UpdateSavedPathsList()
		addon:ClosePopups()
	else
		print("duplicaet name")
	end
end


function CovenantForge_SavedPathEditFrameMixin:OnUpdate()
	local name = addon.savedPathdb.char.paths[self.pathIndex].name
	addon.savedPathdb.char.paths[self.pathIndex] = addon:SavePath()
	addon.savedPathdb.char.paths[self.pathIndex].name = name
	addon:UpdateSavedPathsList()
	addon:ClosePopups()
end


CovenantForge_SavedPathMixin = {}
function CovenantForge_SavedPathMixin:OnClick()
   if not CheckNames(self:GetParent().EditBox:GetText()) then return end

	local Path = addon:SavePath()
	Path.name = self:GetParent().EditBox:GetText(),
	table.insert(addon.savedPathdb.char.paths, Path)
	addon:UpdateSavedPathsList()
end