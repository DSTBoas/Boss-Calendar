name = "Boss Calendar"
description = "Reminds you when bosses respawn\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tMade with 󰀍"

icon_atlas = "modicon.xml"
icon = "modicon.tex"

author = "Boas"
version = "3.4"
forumthread = ""

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true

all_clients_require_mod = false
client_only_mod = true

api_version = 10

folder_name = folder_name or "Boss-Calendar"
if not folder_name:find("workshop-") then
    name = name .. " (dev)"
end

local function AddConfigOption(desc, data, hover)
    return {description = desc, data = data, hover = hover}
end

local function AddConfig(label, name, options, default, hover)
    return {
                label = label,
                name = name,
                options = options,
                default = default,
                hover = hover
           }
end

local function AddSectionTitle(title)
    return AddConfig(title, "", {{description = "", data = 0}}, 0)
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

    local function AddConfigKey(t, key)
        t[#t + 1] = AddConfigOption(key, "KEY_" .. key)
    end

    local function AddDisabledConfigOption(t)
        t[#t + 1] = AddConfigOption("Disabled", false)
    end

    AddDisabledConfigOption(keys)

    local string = ""
    for i = 1, 26 do
        AddConfigKey(keys, string.char(64 + i))
    end

    for i = 1, 10 do
        AddConfigKey(keys, i % 10 .. "")
    end

    for i = 1, 12 do
        AddConfigKey(keys, "F" .. i)
    end

    for i = 1, #specialKeys do
        AddConfigKey(keys, specialKeys[i])
    end
    
    AddDisabledConfigOption(keys)

    return keys
end

local KeyboardOptions = GetKeyboardOptions()

local SettingOptions =
{
    AddConfigOption("Enabled", true),
    AddConfigOption("Disabled", false),
}

local AnnounceStyleOptions =
{
    AddConfigOption("Style 1", 1, "Style 1: Dragonfly respawns on day 21."),
    AddConfigOption("Style 2", 2, "Style 2: Dragonfly respawns in 20 days."),
    AddConfigOption("Style 2.5", 2.5, "Style 2.5: Dragonfly respawns in 19.9 days."),
}

local SayDurationOptions =
{
    AddConfigOption("Short", 3, "Reminders last for 3 seconds"),
    AddConfigOption("Default", 5, "Reminders last for 5 seconds"),
    AddConfigOption("Long", 7, "Reminders last for 7 seconds"),
}

local TimeUnitOptions =
{
    AddConfigOption("Days", true),
    AddConfigOption("Time", false),
}

local OpeningModeOptions =
{
    AddConfigOption("Toggle", true, "Press to open/close the Calendar"),
    AddConfigOption("Hold", false, "Hold to open the Calendar"),
}

local ColorOptions =
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

for i = 1, #ColorOptions do
    ColorOptions[i] = AddConfigOption(ColorOptions[i], ColorOptions[i])
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


    AddSectionTitle("General"),
    AddConfig(
        "Open method",
        "TOGGLE_MODE",
        OpeningModeOptions,
        true,
        SettingsMessage
    ),
    AddConfig(
        "Calendar time units", "CALENDAR_UNITS",
        TimeUnitOptions,
        true,
        SettingsMessage
    ),
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


    AddSectionTitle("Announcing"),
    AddConfig(
        "Announce style",
        "ANNOUNCE_STYLES",
        AnnounceStyleOptions,
        1,
        SettingsMessage
    ),
    AddConfig(
        "Announce time units",
        "ANNOUNCE_UNITS",
        TimeUnitOptions,
        true,
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
