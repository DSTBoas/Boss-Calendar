local Widget = require("widgets/widget")
local Image = require("widgets/image")
local Easing = require("easing")

local half_x, half_y = RESOLUTION_X / 2, RESOLUTION_Y / 2
local screen_width, screen_height = TheSim:GetScreenSize()
local function WorldPosToScreenPos(x, z)
    local map_x, map_y = TheWorld.minimap.MiniMap:WorldPosToMapPos(x, z, 0)
    local screen_x = ((map_x * half_x) + half_x) / RESOLUTION_X * screen_width
    local screen_y = ((map_y * half_y) + half_y) / RESOLUTION_Y * screen_height
    return screen_x, screen_y
end


local PersistentMapIcons = Class(Widget, function(self, mapwidget, scale)
    Widget._ctor(self, "PersistentMapIcons")
    self.root = self:AddChild(Widget("root"))
    self.mapicons = {}

    local MapWidgetOnUpdate = mapwidget.OnUpdate
    mapwidget.OnUpdate = function(mapwidget, ...)
        MapWidgetOnUpdate(mapwidget, ...)
        local zoomLevel = TheWorld.minimap.MiniMap:GetZoom()

        for _, mapicon in ipairs(self.mapicons) do
            local x, y = WorldPosToScreenPos(mapicon.pos.x, mapicon.pos.z)
            mapicon.icon:SetPosition(x, y)
            -- Inefficient but will do for now
            mapicon.icon:SetScale(Easing.outExpo(zoomLevel - 1, 0, .8 - 0.25, 8))
        end
    end
end)

function PersistentMapIcons:AddMapIcon(atlas, image, pos)
    local icon = self.root:AddChild(Image(atlas, image))
    table.insert(self.mapicons, {icon = icon, pos = pos})
end

return PersistentMapIcons
