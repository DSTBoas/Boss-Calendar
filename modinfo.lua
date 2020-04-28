name = "Boss Calendar"

author = "Boas"
version = "3.1"

forumthread = ""
description = "Reminds you when bosses respawn"

api_version = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true

all_clients_require_mod = false
client_only_mod = true
server_filter_tags = {}

folder_name = folder_name or "Boss Calendar"
if not folder_name:find("workshop-") then
    name = name .. " (dev)"
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

local function AddConfig(label, name, options, default, hover)
    return {label = label, name = name, options = options, default = default, hover = hover or ""}
end

local function AddSectionTitle(title)
    return AddConfig(title, "", {{description = "", data = 0}}, 0)
end

local colors = {}
local announce_styles =
{
    {description = "Style 1", data = 1, hover = "Style 1: Dragonfly respawns on day 21."},
    {description = "Style 2", data = 2, hover = "Style 2: Dragonfly respawns in 20 days."},
    {description = "Style 2.5", data = 2.5, hover = "Style 2.5: Dragonfly respawns in 19.9 days."}
}
local say_duration =
{
    {description = "Short", data = 3, hover = "Reminders last for 3 seconds"},
    {description = "Default", data = 5, hover = "Reminders last for 5 seconds"},
    {description = "Long", data = 7, hover = "Reminders last for 7 seconds"}
}
local boolunits =
{
    {description = "Days", data = true},
    {description = "Time", data = false}
}
local boolnohover =
{
    {description = "Enabled", data = true},
    {description = "Disabled", data = false}
}
local bool =
{
    {description = "Toggle", data = true, hover = "Press the keybind to toggle between opening/closing the Calendar"},
    {description = "Hold", data = false, hover = "The Calendar is only shown while you are holding the keybind"}
}

local function CreateDisabled()
    return {description = "Disabled", data = false}
end

local function GetKeyboardKeys()
    local keys = {}
    local SpecialCharacters =
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

    local function AddConfigOption(t, key, val)
        t[#t + 1] = {description = key, data = val or "KEY_" .. key}
    end

    keys[#keys + 1] = CreateDisabled()

    local string = ""
    for i = 1, 26 do
        local char = string.format("%c", (64 + i))
        AddConfigOption(keys, char, 96 + i)
    end

    for i = 1, 9 do
        AddConfigOption(keys, i .. "")
    end
    AddConfigOption(keys, "0")

    for i = 1, 12 do
        AddConfigOption(keys, "F" .. i)
    end

    for i = 1, #SpecialCharacters do
        AddConfigOption(keys, SpecialCharacters[i])
    end
    
    keys[#keys + 1] = CreateDisabled()

    return keys
end

local icons =
{
    {description = "Enabled", data = "igloo"},
    {description = "Disabled", data = false}
}

for i = 1, #COLORNAMES do
    colors[i] = {description = COLORNAMES[i], data = COLORNAMES[i]}
end

local KeyboardOptions = GetKeyboardKeys()
local SettingsMessage = "Set to your liking"

configuration_options =
{
    AddSectionTitle("Keybind"),
    AddConfig("Open key", "OPEN_KEY", KeyboardOptions, 118, "Assign a key"),

    AddSectionTitle("General"),
    AddConfig("Opening mode", "TOGGLE_MODE", bool, true, SettingsMessage),
    AddConfig("Announce style", "ANNOUNCE_STYLES", announce_styles, 1, SettingsMessage),
    AddConfig("Igloo numbers", "IGLOO_NUMBERS", boolnohover, true, SettingsMessage),
    AddConfig("Map icons", "IGLOO_ICON", icons, "igloo", SettingsMessage),

    AddSectionTitle("Reminder"),
    AddConfig("Reminder color", "REMINDER_COLOR", colors, "Green", SettingsMessage),
    AddConfig("Reminder duration", "REMINDER_DURATION", say_duration, 5, SettingsMessage),

    AddSectionTitle("Advanced"),
    AddConfig("Boss Calendar time units", "CALENDAR_UNITS", boolunits, true, SettingsMessage),
    AddConfig("Announce time units", "ANNOUNCE_UNITS", boolunits, true, SettingsMessage),
}
