if GetLocale() ~= "zhCN" then return end

local addonName, addon = ...
local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonName, "zhCN", false, true)
_G.alal=L
if not L then return end

_G["BINDING_HEADER_COVENANTFORGE"] = addonName
_G["BINDING_NAME_COVENANTFORGE_BINDING_TOGGLE_SOULBINDS"] = "切换查看者"

--Options
L["Options"] = "选项"
L["General Options"] = "通用选项"
L["Show Soulbind Name"] = "显示灵魂羁绊名字"
L["Show Node Ability Names"] = "显示节点技能名"
L["Show Weight as Percent"] = "评分按百分比显示"
L["Show Weights"] = "显示评分"
L["Hide Weight Values That Are 0"] = "评分为0时不显示"
L["Disable FX"] = "关闭视觉特效"
L["Show Conduit Rank On Tooltip"] = "在鼠标提示上显示导灵器等级"

L["PR"] = "团本前"
L["T26"] = "T26团本"
--L["Base: %s/%s\nCurrent: %s/%s\nMax Total: %s"] = true
L["Base: %s/%s\nCurrent: %s/%s"] = "基础: %s/%s\n当前: %s/%s"
L["%s - Rank:%s |cffffffff(%s)|r"] = "%等级:%s |cffffffff(%s)|r"

L["Current: %s/%s\nMax Possible: %s"] = "当前: %s/%s\n最大评分: %s"
L["%s (Rank %d)"] = "%s (等级 %d)"

COVENATNFORGE_UPDATE_PATH = "更新方案"
COVENATNFORGE_DELETE_PATH = "删除方案"
COVENATNFORGE_CREATE_PATH = "新建方案"

--右上角四个标签
L["Learned Conduits"] = "已有导灵器"
L["Saved Paths"] = "保存方案"
L["Avaiable Conduits"] = "可获得的导灵器"
L["Conduits"] = "导灵器"
L["Weights"] = "评分"

--Saved Paths
L["Name Already Exists"] = "名字已存在"
L["Requires the Forge of Bonds to modify."] = "需要完成羁绊熔炉任务."
L["Saved Path %s has been loaded."] = "保存方案 %s 已加载."
L["Soulbinds"] = "灵魂羁绊"
L["All"] = "全部"
L["Row"] = "行"
L["Update Path"] = "更新方案"
L["Delete Path"] = "删除方案"


L["Percent Value"] = "显示百分比"
L["Create New Blank Profile"] = "新建空配置"
L["Copy Current Profile"] = "复制当前配置"
L["Delete Current Profile"] = "删除当前配置"

