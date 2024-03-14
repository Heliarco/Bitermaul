waves = {}

-- /c    local s = game.surfaces['nauvis'] local p = {0,0} s.create_entity{name = "big-biter", position = p, force = game.forces['enemy']}
-- https://lua-api.factorio.com/latest/classes/LuaUnitGroup.html

-- what we want to work with here is called LuaUnitGroups
-- how to get areas
-- local area = game.get_surface("nauvis").get_script_area("1"),  or get script point i presume


local spawn_areas = {
    { name = "spawn_top_left"},
    { name = "spawn_top"},
    { name = "spawn_top_right"},
    { name = "spawn_middle_1"},
    { name = "spawn_middle_2"},
    { name = "spawn_left"},
    { name = "spawn_right"},
    { name = "spawn_bottom_left"},
    { name = "spawn_bottom_right"},
    { name = "spawn_bottom"}
}
local goal_area = { name = "goal" }

local waypoints = {
    { name = "waypoint_top_left"},
    { name = "waypoint_top"},
    { name = "waypoint_top_right"},
    { name = "waypoint_left"},
    { name = "waypoint_middle"},
    { name = "waypoint_right"},
    { name = "waypoint_bottom_left"},
    { name = "waypoint_bottom_right"},
    { name = "waypoint_goal"}
}

---@type LuaSurface
local surface = nil

function waves.oninit()
    surface = game.surfaces['nauvis']
    -- We pull out all the named areas and points from the scenario right from the start
    -- That way we can save them and also we check they exist :)
    for index, value in pairs(spawn_areas) do
        spawn_areas[index].script_area = surface.get_script_area(value.name)
    end
    goal_area.script_area = surface.get_script_area(goal_area.name)

    for index, value in pairs(waypoints) do
        waypoints[index].script_position = surface.get_script_position(value.name)
    end


end


function waves.spawn_wave()
    for index, value in pairs(spawn_areas) do
        ---@type ScriptArea
        local script_area = value.script_area
        local position = { 
            (script_area.area.left_top.x + script_area.area.right_bottom.x)/2,
            (script_area.area.left_top.y + script_area.area.right_bottom.y)/2,
        } 
        local entity = surface.create_entity {name="small-biter", position = position, force="enemy"}        
    end
    

    

end