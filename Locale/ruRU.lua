local addonName, addon = ...
local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonName, "ruRU", true, true)

if not L then return end

_G["BINDING_HEADER_COVENANTFORGE"] = addonName
_G["BINDING_NAME_COVENANTFORGE_BINDING_TOGGLE_SOULBINDS"] = "Переключить просмотрщик медиумов"

--Options
L["General Options"] = "Общие настройки"
L["Show Soulbind Name"] = "Показать имя медиума"
L["Show Node Ability Names"] = "Показать названия способностей"
L["Show Weight as Percent"] = "Показать вес в процентах"


L["PR"] = "Пре Рейд"
L["T26"] = "Тир 26"
--L["Base: %s/%s\nCurrent: %s/%s\nMax Total: %s"] = true
L["Base: %s/%s\nCurrent: %s/%s"] = "Основание: %s/%s\nПоток: %s/%s"

