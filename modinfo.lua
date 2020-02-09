name = "Boss Calendar"

author = "Boas"
version = "101.111"

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

local keyslist = {}
local string = ""
for i = 1, 26 do
	local ch = string.format("%c", (65 + i - 1))
	keyslist[i] = {description = ch, data = ch}
end

configuration_options = 
{
	{
		name = "OPEN_CALENDAR",
		label = "Key to open the Boss Calendar",
		options = keyslist,
		default = "V",
	},
}