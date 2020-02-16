name = "Boss Calendar"

author = "Boas"
version = "1"

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

local function AddConfig(label, name, options, default, hover)
    return {label = label, name = name, options = options, default = default, hover = hover or ""}
end

local function AddSectionTitle(title)
    return AddConfig(title, "", {{description = "", data = 0}}, 0)
end

local boolnohover = {{description = "Enabled", data = true },{description = "Disabled", data = false}}
local bool = {{description = "Toggle", data = true, hover = "Toggle: Press to open / close the Boss Calendar" },{description = "Hold", data = false, hover = "Hold: Holding the key opens the Boss Calendar"}}
local keyslist = {{description = "Disabled", data = false}}
local icons = {{description = "Pronounced", data = "iglobig"},{description = "Subtle", data = "iglo"}}
local string = ""
for i = 1, 26 do
	local ch = string.format("%c", (64 + i))
	keyslist[i+1] = {description = ch, data = ch:lower():byte()}
end

configuration_options = 
{
	AddSectionTitle("Keybinds"),
	AddConfig("Key to Open", "OPENKEY", keyslist, 118, "Assign a key"),
	AddSectionTitle("Settings"),
	AddConfig("Open Mode", "TOGGLEMODE", bool, true, "Toggle / Hold"),
	AddConfig("Map icon size", "IGLO_ICON_SIZE", icons, "iglobig", "Pronounced / Subtle"),
	AddConfig("Map icons", "MAPICONS_ENABLED", boolnohover, true, "Enabled / Disabled"),
	AddConfig("Igloo numbers", "IGLO_NUMBERS", boolnohover, true, "Enabled / Disabled")
}