if GetLocale() ~= "zhTW" then return end

local addonName, addon = ...
local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonName, "zhTW", false, true)
_G.alal=L
if not L then return end

_G["BINDING_HEADER_COVENANTFORGE"] = addonName
_G["BINDING_NAME_COVENANTFORGE_BINDING_TOGGLE_SOULBINDS"] = "切換靈魂之絆視窗"

--Options
L["Options"] = "選項"
L["General Options"] = "一般選項"
L["Show Soulbind Name"] = "顯示靈魂之絆名稱"
L["Show Node Ability Names"] = "顯示節點技能名稱"
L["Show Weights"] = "顯示評分"
L["Hide Weight Values That Are 0"] = "隱藏評分值為0的"
L["Show Weight as Percent"] = "顯示評分為百分比"
L["Disable FX"] = "停用FX"
L["Show Conduit Rank On Tooltip"] = "在提示上顯示傳導器等級"

--Tabs
L["Learned Conduits"] = "已學習傳導器"
L["Conduits"] = "傳導器"
L["Weights"] = "評分"
L["Avaiable Conduits"]= "可用傳導器"
L["Saved Paths"] = "儲存路徑"


L["PR"] = "團隊前夕"
L["T26"] = "T26團本"
--L["Base: %s/%s\nCurrent: %s/%s\nMax Total: %s"] = true
L["Base: %s/%s\nCurrent: %s/%s"] = "基礎: %s/%s\n當前： %s/%s"
L["%s - Rank:%s |cffffffff(%s)|r"] = "%s - 等級: %s |cffffffff(%s)|r"

L["Current: %s/%s\nMax Possible: %s"] = "當前： %s/%s\n最大可能: %s"
L["%s (Rank %d)"] = "%s (等級 %d)"

COVENATNFORGE_UPDATE_PATH = "更新路徑"
COVENATNFORGE_DELETE_PATH = "刪除路徑"
COVENATNFORGE_CREATE_PATH = "建立路徑"

--Saved Paths
L["Name Already Exists"] = "名稱已經存在"
L["Requires the Forge of Bonds to modify."] = "需要魂絆熔爐來更改。"
L["Saved Path %s has been loaded."] = "儲存路徑 %s 已經載入。"

L["Percent Value"] = "百分比值"
L["Soulbinds"] = "靈魂之絆"
L["All"] = "全部"

L["Create New Blank Profile"] = "建立新的空白設定檔"
L["Copy Current Profile"] = "複製當前的設定檔"
L["Delete Current Profile"] = "刪除當前的設定檔"