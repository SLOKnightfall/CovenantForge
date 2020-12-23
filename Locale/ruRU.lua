if GetLocale() ~= "ruRU" then return end
local addonName, addon = ...
local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonName, "ruRU", false, true)

if not L then return end

_G["BINDING_HEADER_COVENANTFORGE"] = addonName
_G["BINDING_NAME_COVENANTFORGE_BINDING_TOGGLE_SOULBINDS"] = "Переключить просмотрщик медиумов"

--Options
L["Options"] = "Настройки"
L["General Options"] = "Общие настройки"
L["Show Soulbind Name"] = "Показать имя медиума"
L["Show Node Ability Names"] = "Показать названия способностей"
L["Show Weights"] = "Показать веса"
L["Hide Weight Values That Are 0"] = "Скрыть нулевые значения веса"
L["Show Weight as Percent"] = "Показать вес в процентах"
L["Disable FX"] = "Отключить FX"
L["Show Conduit Rank On Tooltip"] = "Показать рейтинг канала во всплывающей подсказке"
--L["Soulbind Frame Scale"] = true

--Tabs
L["Learned Conduits"] = "Выученные каналы"
L["Weights"] = "Вес"
L["Avaiable Conduits"]= "Доступные контексты"
L["Saved Paths"] = "Сохраненные пути"


L["PR"] = "HERODAMAGE - Пре Рейд"
L["T26"] = "HERODAMAGE -Тир 26"
--L["Base: %s/%s\nCurrent: %s/%s\nMax Total: %s"] = true
L["Base: %s/%s\nCurrent: %s/%s"] = "Основание: %s/%s\nПоток: %s/%s"
L["%s - Rank:%s |cffffffff(%s)|r"] = "%s - Ранг:%s |cffffffff(%s)|r"

L["Current: %s/%s\nMax Possible: %s"] = "Текущий: %s/%s\nМаксимально возможное: %s"
L["%s (Rank %d)"] = "%s (Ранг %d)"

COVENATNFORGE_UPDATE_PATH = "Улучшить путь"
COVENATNFORGE_DELETE_PATH = "Удалить путь"
COVENATNFORGE_CREATE_PATH = "Создать путь"

--Saved Paths
L["Name Already Exists"] = "Имя уже существует"
L["Requires the Forge of Bonds to modify."] = "Требует модификации кузни душ"
L["Saved Path %s has been loaded."] = "Сохраненный путь %s загружен"



L["Percent Value"] = "Процентное значение"
