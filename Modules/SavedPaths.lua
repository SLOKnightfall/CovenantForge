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
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local function SortNodes(data)
	local sortedNodes = {}
	for _, nodes in pairs(data) do table.insert(sortedNodes, nodes) end
	table.sort(sortedNodes, function(a,b) return a.row < b.row end)
	return sortedNodes
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


function addon:PathTooltip(parent, index)
	if not addon.savedPathdb.char.paths[index] then return end

	local data = addon.savedPathdb.char.paths[index]
	local covenantData = C_Covenants.GetCovenantData(data.covenantID)
	local soulbindData = C_Soulbinds.GetSoulbindData(data.soulbindID)
	local r,g,b = COVENANT_COLORS[data.covenantID]:GetRGB()

	GameTooltip:SetOwner(parent.frame, "ANCHOR_RIGHT")

	GameTooltip:AddLine(("%s - %s"):format(covenantData.name, soulbindData.name),r,g,b)
	GameTooltip:AddLine(" ")

	 local pathList = SortNodes(data.data)

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


function addon:ShowNodeTooltip(parent, data)
	if not data then return end

	GameTooltip:SetOwner(parent.frame, "ANCHOR_RIGHT")

	if data.conduitID > 0 then
		local collectionData = C_Soulbinds.GetConduitCollectionData(data.conduitID)
		local quality = C_Soulbinds.GetConduitQuality(collectionData.conduitID, collectionData.conduitRank)
		local spellID = C_Soulbinds.GetConduitSpellID(collectionData.conduitID, collectionData.conduitRank)
		local name = GetSpellInfo(spellID)
		--local desc = GetSpellDescription(spellID)
		local colormarkup = DARKYELLOW_FONT_COLOR:GenerateHexColorMarkup()
		GameTooltip:SetConduit(data.conduitID, collectionData.conduitRank)
		addon:ConduitTooltip_Rank(GameTooltip, collectionData.conduitRank, data.row + 1)
	else
		local spellID = data.spellID
		local name = GetSpellInfo(spellID)
		local desc = GetSpellDescription(spellID)
		GameTooltip:AddLine(string.format("Row %d: |cffffffff%s|r", data.row + 1 , name))
		GameTooltip:AddLine(desc, nil, nil, nil, true)
	end
		
	GameTooltip:Show()
end


function addon:SavePath()
	local covenantID = C_Covenants.GetActiveCovenantID()
	local soulbindID = SoulbindViewer:GetOpenSoulbindID()
	local pathData, icon  = GetPathData()

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


function addon:LoadPath(index, macro)
	local pathData = addon.savedPathdb.char.paths[index]

	if not pathData then return end
	if not C_Soulbinds.CanSwitchActiveSoulbindTreeBranch() then
		print(SOULBIND_NODE_UNSELECTED)
		return
	end

	local covenantData = C_Covenants.GetCovenantData(pathData.covenantID)
	local soulbindIDs = covenantData.soulbindIDs
	local soulbindID = pathData.soulbindID

	local currentSoulbindId = SoulbindViewer:GetOpenSoulbindID()
	local currentSoulbindData = C_Soulbinds.GetSoulbindData(currentSoulbindId)

	if not C_Soulbinds.CanModifySoulbind() then
		for nodeID, pathData in pairs(pathData.data) do
			local currentNode = C_Soulbinds.GetNode(nodeID)
			if currentNode.conduitID ~= pathData.conduitID then
				print(L["Requires the Forge of Bonds to modify."])
				return
			end
		end
	end

	if currentSoulbindId ~= soulbindID then
		SoulbindViewer.SelectGroup.buttonGroup:SelectAtIndex(tIndexOf(soulbindIDs, soulbindID))
	end
	
	if C_Soulbinds.GetActiveSoulbindID() ~= soulbindID and macro then
		C_Soulbinds.ActivateSoulbind(soulbindID)
	elseif C_Soulbinds.GetActiveSoulbindID() ~= soulbindID then
		SoulbindViewer:OnActivateSoulbindClicked()
	end

	for i, node in pairs(currentSoulbindData.tree.nodes) do
		if C_Soulbinds.IsNodePendingModify(node.ID) then
			C_Soulbinds.UnmodifyNode(node.ID)
			C_Soulbinds.UnmodifyNode(node.ID)
		end
	end

	for nodeID, pathData in pairs(pathData.data) do
		local currentNode = C_Soulbinds.GetNode(nodeID)

		if C_Soulbinds.IsNodePendingModify(nodeID) then
			C_Soulbinds.UnmodifyNode(nodeID)
			C_Soulbinds.UnmodifyNode(nodeID)
		end

		if currentNode.conduitID ~= pathData.conduitID then
			C_Soulbinds.ModifyNode(nodeID, pathData.conduitID, 0)
		end

		if pathData.state == 3 then
			C_Soulbinds.SelectNode(nodeID)
		end
	end

	if C_Soulbinds.HasAnyPendingConduits() then
		SoulbindViewer:OnCommitConduitsClicked()
	end

	print((L["Saved Path %s has been loaded."]):format(pathData.name))
end


function addon:MacroLoad(pathName)
	local isfound = false
	for i, data in ipairs(addon.savedPathdb.char.paths) do
		if data.name == pathName then
			isfound = i
			break
		end
	end

	if not isfound then return false end
	addon:LoadPath(isfound, true)
end


--Saved Path Popup Menu
function addon:ShowPopup(popup, index)
	if popup == "COVENANTFORGE_UPDATEPATHPOPUP" then 
		StaticPopupSpecial_Show(CovenantForge_SavedPathEditFrame)
		local data = addon.savedPathdb.char.paths[index]
		CovenantForge_SavedPathEditFrame.EditBox:SetText(data.name)
		CovenantForge_SavedPathEditFrame.pathIndex = index
	elseif popup == "COVENANTFORGE_UPDATEWEIGHTPOPUP" then 
		StaticPopupSpecial_Show(CovenantForge_WeightsEditFrame)
	end
end


function addon:ClosePopups()
	StaticPopupSpecial_Hide(CovenantForge_SavedPathEditFrame)
	StaticPopupSpecial_Hide(CovenantForge_WeightsEditFrame)
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
		print(L["Name Already Exists"])
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


function addon:UpdateSavedPathsList()
	if not SoulbindViewer or (SoulbindViewer and not SoulbindViewer:IsShown()) or
 		not addon.savedPathdb.char.paths or not addon.scrollcontainer then return end

	local scrollcontainer = addon.scrollcontainer
	scrollcontainer:ReleaseChildren()
	scrollcontainer:SetPoint("TOPLEFT", addon.PathStorageFrame,"TOPLEFT", 0, -55)
	scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow") -- probably?
	scrollcontainer:AddChild(scroll)

	for i, data in ipairs(addon.savedPathdb.char.paths) do
		local soulbindData = C_Soulbinds.GetSoulbindData(data.soulbindID)
		local container = AceGUI:Create("SimpleGroup") 
		container:SetLayout("Fill")

		local topHeading = AceGUI:Create("Heading") 
		topHeading:SetRelativeWidth(1)
		topHeading:SetHeight(5)
		scroll:AddChild(topHeading)
		--container:AddChild(topHeading)
		local InteractiveLabel = AceGUI:Create("InteractiveLabel")
		InteractiveLabel:SetText(soulbindData.name..": "..data.name.."\n \n  \n  \n  \n ")
		InteractiveLabel:SetJustifyH("TOP")
		InteractiveLabel.label:SetPoint("TOP", container.frame, "TOP", 0 ,10)
		InteractiveLabel.label:SetHeight(InteractiveLabel.label:GetStringHeight())
		--InteractiveLabel:SetImage(data.icon)
		InteractiveLabel:SetImage(data.icon)
		InteractiveLabel:SetImageSize(1,35)
		InteractiveLabel:SetHeight(35)
		InteractiveLabel.image:ClearAllPoints()
		--InteractiveLabel.image:SetPoint("LEFT",-999)
		InteractiveLabel.image:SetAlpha(0)
		InteractiveLabel:SetRelativeWidth(1)
		--InteractiveLabel:SetPoint("CENTER")
		InteractiveLabel:SetCallback("OnClick", function() addon:LoadPath(i) end)
		InteractiveLabel:SetCallback("OnEnter", function() addon:PathTooltip(InteractiveLabel, i) end)
		InteractiveLabel:SetCallback("OnLeave", function() GameTooltip:Hide() end)

		local UpdateButton =  AceGUI:Create("Icon") 
		UpdateButton:SetImage("Interface/Buttons/UI-OptionsButton")
		UpdateButton:SetImageSize(15,15)
		UpdateButton:SetHeight(18)
		UpdateButton:SetWidth(18)

		UpdateButton:SetCallback("OnClick", function()
				if (not StaticPopup_Visible("COVENANTFORGE_UPDATEPATHPOPUP")) then
				addon:ShowPopup("COVENANTFORGE_UPDATEPATHPOPUP", i)
				end  end)
		UpdateButton:SetCallback("OnEnter", function() GameTooltip:SetOwner(UpdateButton.frame, "ANCHOR_RIGHT"); GameTooltip:AddLine(L["Options"]); GameTooltip:Show() end)
		UpdateButton:SetCallback("OnLeave", function() GameTooltip:Hide() end)
		UpdateButton:SetRelativeWidth(.1)
		UpdateButton.index = i


		container:AddChild(InteractiveLabel)
		container:AddChild(UpdateButton)

		UpdateButton:ClearAllPoints()
		UpdateButton.frame:SetPoint("TOPRIGHT",container.frame,"TOPRIGHT", 0, 5)
		UpdateButton.frame:SetFrameLevel(200)

		container:SetHeight(35)
		container:SetFullWidth(true)
		--scroll:AddChild(container)
		container:SetAutoAdjustHeight(false)

		--container = AceGUI:Create("SimpleGroup") 
		--container:SetLayout("Flow")
		--container:SetFullWidth(true)
		--container:SetHeight(30)
		--container:SetAutoAdjustHeight(false)
		local sortedNodes = SortNodes(data.data)
		local index = 0
		for id, data in pairs(sortedNodes) do
			local nodeIcon = AceGUI:Create("Icon")
			if data.conduitID > 0 then 
				local spellID = C_Soulbinds.GetConduitSpellID(data.conduitID, 1)
				local _,_, icon = GetSpellInfo(spellID)
				nodeIcon:SetImage(icon)
			else
				local _,_, icon = GetSpellInfo(data.spellID)
				nodeIcon:SetImage(icon)
			end
			nodeIcon:SetImageSize(25,25)
			nodeIcon:SetWidth(26)
			nodeIcon:SetCallback("OnClick", function() addon:LoadPath(i) end)
			nodeIcon:SetCallback("OnEnter", function() addon:ShowNodeTooltip(nodeIcon, data) end)
			nodeIcon:SetCallback("OnLeave", function() GameTooltip:Hide() end)
			container:AddChild(nodeIcon)
			nodeIcon.frame:SetPoint("BOTTOMLEFT", container.frame, "BOTTOMLEFT", 26 * index, -7)
			nodeIcon.frame:SetFrameLevel(200)
			index = index + 1
		end
		scroll:AddChild(container)
	end
end


