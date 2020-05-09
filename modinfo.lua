name = "Boss Calendar"
description = "Reminds you when bosses respawn"

icon_atlas = "modicon.xml"
icon = "modicon.tex"

author = "Boas"
version = "3.2"
forumthread = ""

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true

all_clients_require_mod = false
client_only_mod = true

api_version = 10

folder_name = folder_name or "Equipment-Control"
if not folder_name:find("workshop-") then
    name = name .. " (dev)"
end

local function AddConfig(label, name, options, default, hover)
    return {
                label = label,
                name = name,
                options = options,
                default = default,
                hover = hover or ""
           }
end

local function AddSectionTitle(title)
    return AddConfig(title, "", {{description = "", data = 0}}, 0)
end

local function CreateOption(desc, data, hover)
    return {description = desc, data = data, hover = hover}
end

local function GetKeyboardOptions()
    local keys = {}
    local specialKeys =
    {
        "TAB",
        "MINUS",
        "SPACE",
        "ENTER",
        "ESCAPE",
        "INSERT",
        "DELETE",
        "END",
        "PAUSE",
        "PRINT",
        "CAPSLOCK",
        "SCROLLOCK",
        "RSHIFT",
        "LSHIFT",
        "SHIFT",
        "RCTRL",
        "LCTRL",
        "CTRL",
        "RALT",
        "LALT",
        "ALT",
        "BACKSPACE",
        "PERIOD",
        "SLASH",
        "SEMICOLON",
        "LEFTBRACKET",
        "RIGHTBRACKET",
        "BACKSLASH",
        "TILDE",
        "UP",
        "DOWN",
        "RIGHT",
        "LEFT",
        "PAGEUP",
        "PAGEDOWN"
    }

    local function AddConfigOption(t, key)
        t[#t + 1] = {description = key, data = "KEY_" .. key}
    end

    local function AddDisabledConfigOption(t)
        t[#t + 1] = {description = "Disabled", data = false}
    end

    AddDisabledConfigOption(keys)

    local string = ""
    for i = 1, 26 do
        AddConfigOption(keys, string.format("%c", 64 + i))
    end

    for i = 1, 9 do
        AddConfigOption(keys, i .. "")
    end
    AddConfigOption(keys, "0")

    for i = 1, 12 do
        AddConfigOption(keys, "F" .. i)
    end

    for i = 1, #specialKeys do
        AddConfigOption(keys, specialKeys[i])
    end
    
    AddDisabledConfigOption(keys)

    return keys
end

local COLORNAMES =
{
    "White",
    "Red",
    "Coral",
    "Orange",
    "Yellow",
    "Khaki",
    "Chocolate",
    "Brown",
    "Green",
    "Light Green",
    "Cyan",
    "Blue",
    "Light Blue",
    "Purple",
    "Pink"
}

local KeyboardOptions = GetKeyboardOptions()

local SettingOptions =
{
    CreateOption("Enabled", true),
    CreateOption("Disabled", false),
}

local AnnounceStyleOptions =
{
    CreateOption("Style 1", 1, "Style 1: Dragonfly respawns on day 21."),
    CreateOption("Style 2", 2, "Style 2: Dragonfly respawns in 20 days."),
    CreateOption("Style 2.5", 2.5, "Style 2.5: Dragonfly respawns in 19.9 days."),
}

local SayDurationOptions =
{
    CreateOption("Short", "Reminders last for 3 seconds"),
    CreateOption("Default", "Reminders last for 5 seconds"),
    CreateOption("Long", "Reminders last for 7 seconds"),
}

local TimeUnitOptions =
{
    CreateOption("Days", true),
    CreateOption("Time", false),
}

local OpeningModeOptions =
{
    CreateOption("Toggle", true, "Press the keybind to toggle between opening/closing the Calendar"),
    CreateOption("Hold", false, "The Calendar is only shown while you are holding the keybind"),
}

local ColorOptions = {}

for i = 1, #COLORNAMES do
    ColorOptions[i] = CreateOption(COLORNAMES[i], COLORNAMES[i])
end

local SettingsMessage = "Set to your liking"
local AssignKeyMessage = "Assign a key"

configuration_options =
{
    AddSectionTitle("Keybind"),
    AddConfig(
        "Open key",
        "OPEN_KEY",
        KeyboardOptions,
        "KEY_V",
        AssignKeyMessage
    ),


    AddSectionTitle("Calendar"),
    AddConfig(
        "Open method",
        "TOGGLE_MODE",
        OpeningModeOptions,
        true,
        SettingsMessage
    ),
    AddConfig(
        "Time units", "CALENDAR_UNITS",
        TimeUnitOptions,
        true,
        SettingsMessage
    ),


    AddSectionTitle("Announce"),
    AddConfig(
        "Announce style",
        "ANNOUNCE_STYLES",
        AnnounceStyleOptions,
        1,
        SettingsMessage
    ),
    AddConfig(
        "Time units",
        "ANNOUNCE_UNITS",
        TimeUnitOptions,
        true,
        SettingsMessage
    ),


    AddSectionTitle("MacTusk"),
    AddConfig(
        "Igloo numbers",
        "IGLOO_NUMBERS",
        SettingOptions,
        true,
        SettingsMessage
    ),
    AddConfig(
        "Map icons",
        "IGLOO_ICON",
        SettingOptions,
        "igloo",
        SettingsMessage
    ),


    AddSectionTitle("Reminder"),
    AddConfig(
        "Reminder color",
        "REMINDER_COLOR",
        ColorOptions,
        "Green",
        SettingsMessage
    ),
    AddConfig(
        "Reminder duration",
        "REMINDER_DURATION",
        SayDurationOptions,
        5,
        SettingsMessage
    ),
}
