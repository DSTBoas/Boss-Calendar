local GLOBAL = GLOBAL
local rawget = GLOBAL.rawget

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
    inst:DoTaskInTime(0, function()
        BossCalendar:AddCamp(inst)
    end)
end
AddPrefabPostInit("walrus_camp", WalrusCampPostInit)

for _, prefab in pairs
{
    "yellowgem",
    "hivehat",
    "shroom_skin",
    "klaussackkey",
    "blowdart_pipe",
    "malbatross_beak",
    "skeletonhat",
    "singingshell_octave5"
} do
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(0, function() 
            BossCalendar:ValidateDeath(inst) 
        end)
    end)
end

local function GetConfigByte(config)
    return rawget(GLOBAL, GetModConfigData(config)) or 0
end

if GetConfigByte("OPEN_KEY") then
    local OPEN_KEY = GetConfigByte("OPEN_KEY")
    local TOGGLE_MODE = GetModConfigData("TOGGLE_MODE")
    local TheInput = GLOBAL.TheInput

    local function getActiveScreenName()
        local activeScreen = TheFrontEnd:GetActiveScreen()
        return activeScreen and activeScreen.name or ""
    end

    local function canToggle()
        local activeScreenName = getActiveScreenName()
        return activeScreenName == "HUD" or activeScreenName == "Boss Calendar"
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
    inst:DoTaskInTime(0, function() 
        BossCalendar:Init(inst) 
    end)
end
AddPlayerPostInit(Init)

AddSimPostInit(function()
    BossCalendar:LoadIgloos()
end)

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
