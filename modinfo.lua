name = "Boss Calendar"

author = "Boas"
version = "1.0"

forumthread = ""
description = "Keeps a record of the respawn durations of the bosses YOU kill."

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
local announce_styles = {
	{description = "Style 1", data = 1, hover = "Example: Dragonfly respawns on day 21." },
	{description = "Style 2", data = 2, hover = "Example: Dragonfly respawns in 20 days."},
	{description = "Style 2.5", data = 2.5, hover = "Example: Dragonfly respawns in 19.9 days."}
}
local boolunits = {
	{description = "Days", data = true},
	{description = "Hours / Minutes", data = false}
}
local boolnohover = {
	{description = "Enabled", data = true },
	{description = "Disabled", data = false}
}
local bool = {
	{description = "Toggle", data = true, hover = "Toggle: Press to open / close the Boss Calendar" },
	{description = "Hold", data = false, hover = "Hold: Holding the key opens the Boss Calendar"}
}
local keyslist = {
	{description = "Disabled", data = false}
}
local icons = {
	{description = "Big", data = "iglobig"},
	{description = "Small", data = "iglo"}
}

for i = 1 , #COLORNAMES do
	colors[i] = {description = COLORNAMES[i], data = COLORNAMES[i]}
end

local string = ""
for i = 1, 26 do
	local ch = string.format("%c", (64 + i))
	keyslist[i + 1] = {description = ch, data = ch:lower():byte()}
	if i < 13 then
		keyslist[27 + i] = {description = "F" .. i, data = 281 + i}
	end
end

configuration_options = 
{
	AddSectionTitle("Keybinds"),
	AddConfig("Key to open", "OPENKEY", keyslist, 118, "Assign a key"),
	AddSectionTitle("Settings"),
	AddConfig("Open mode", "TOGGLEMODE", bool, true, "Toggle / Hold"),
	AddConfig("Boss Calendar time units", "TIME_UNITS", boolunits, true, "Game days / Real time"),
	AddConfig("Announce time units", "ANNOUNCE_UNITS", boolunits, true, "Game days / Real time"),
	AddConfig("Announce style", "ANNOUNCE_STYLES", announce_styles, 1, "Choose a style"),
	AddConfig("Reminder color", "SAYCOLOR", colors, "Green", "Choose a color"),
	AddConfig("Map icon size", "IGLO_ICON_SIZE", icons, "iglobig", "Big / Small"),
	AddConfig("Map icons", "MAPICONS_ENABLED", boolnohover, true, "Igloo map icons have numbers"),
	AddConfig("Igloo numbering", "IGLO_NUMBERS", boolnohover, true, "Igloos display their number above them")
}
