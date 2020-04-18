local GLOBAL = GLOBAL
local BossCalendar = GLOBAL.require("screens/bosscalendar")

Assets =
{
    Asset("ATLAS", "images/skull.xml"),
    Asset("ATLAS", "images/npcs.xml"),
    Asset("ATLAS", "images/igloo.xml"),
}
AddMinimapAtlas("images/igloo.xml")

if GetModConfigData("IGLOO_ICON") then
    local function MapWidgetPostConstruct(self)
        BossCalendar:AddMapIcons(self)
    end
    AddClassPostConstruct("widgets/mapwidget", MapWidgetPostConstruct) 
end

local function WalrusCampPostInit(inst)
    inst:DoTaskInTime(0, BossCalendar.AddCamp, inst)
end
AddPrefabPostInit("walrus_camp", WalrusCampPostInit)

do
    local prefabs =
    {
        "yellowgem",
        "hivehat",
        "shroom_skin",
        "klaussackkey",
        "blowdart_pipe",
        "malbatross_beak",
        "skeletonhat"
    }
    for i = 1, #prefabs do
        AddPrefabPostInit(prefabs[i], function(inst)
            inst:DoTaskInTime(0, function() BossCalendar:ValidateDeath(inst) end)
        end)
    end
end

if GetModConfigData("OPEN_KEY") then
    local OPEN_KEY, TOGGLE_MODE, TheInput = GetModConfigData("OPEN_KEY"), GetModConfigData("TOGGLE_MODE"), GLOBAL.TheInput

    local function canToggle()
        return TheFrontEnd
           and TheFrontEnd.GetActiveScreen
           and TheFrontEnd:GetActiveScreen().name
           and (TheFrontEnd:GetActiveScreen().name == "HUD" or TheFrontEnd:GetActiveScreen().name == "Boss Calendar")
    end

    local function displayCalendar()
        if canToggle() then
            if BossCalendar:Open() then
                TheFrontEnd:PushScreen(BossCalendar)
            elseif TOGGLE_MODE then
                BossCalendar:Close()
            end
        end
    end

    local function closeCalendar()
        if canToggle() then
            BossCalendar:Close()
        end
    end

    if TOGGLE_MODE then
        TheInput:AddKeyUpHandler(OPEN_KEY, displayCalendar)
    else
        TheInput:AddKeyDownHandler(OPEN_KEY, displayCalendar)
        TheInput:AddKeyUpHandler(OPEN_KEY, closeCalendar)
    end
end

local function Init(inst)
    inst:DoTaskInTime(0, function() BossCalendar:Init(inst) end)
end
AddPlayerPostInit(Init)

AddSimPostInit(BossCalendar.LoadIgloos)

BossCalendar:SetSettings(
    {
        IGLOO_ICON = GetModConfigData("IGLOO_ICON"),
        IGLOO_NUMBERS = GetModConfigData("IGLOO_NUMBERS"),
        REMINDER_COLOR = GetModConfigData("REMINDER_COLOR"),
        REMINDER_DURATION = GetModConfigData("REMINDER_DURATION"),
        CALENDAR_UNITS = GetModConfigData("CALENDAR_UNITS"),
        ANNOUNCE_STYLES = GetModConfigData("ANNOUNCE_STYLES"),
        ANNOUNCE_UNITS = GetModConfigData("ANNOUNCE_UNITS"),
    }
)
