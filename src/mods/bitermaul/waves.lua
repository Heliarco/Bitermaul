-- Setting up the return object


local pathfinding_flags = {
    allow_destroy_friendly_entities = false,
    allow_paths_through_own_entities = false,
    cache = true,
    prefer_straight_paths = false, -- lol
    low_priority = false,
    no_break = false
}


-- Info we know about the map
---@type table<string, number>
local spawn_area_name_weights = {
    -- ["spawn_top_left"] = 1,
    -- ["spawn_top"] = 1,
    -- ["spawn_top_right"] = 1,
    -- ["spawn_middle_1"] = 0.5,
    -- ["spawn_middle_2"] = 0.5,
    -- ["spawn_left"] = 1,
    -- ["spawn_right"] = 1,
    -- ["spawn_bottom_left"] = 1,
    -- ["spawn_bottom_right"] = 1,
    -- ["spawn_bottom"] = 1

    ["spawn_top_left"] = 1,
    ["spawn_top"] = 0,
    ["spawn_top_right"] = 0,
    ["spawn_middle_1"] = 0,
    ["spawn_middle_2"] = 0,
    ["spawn_left"] = 0,
    ["spawn_right"] = 0,
    ["spawn_bottom_left"] = 0,
    ["spawn_bottom_right"] = 0,
    ["spawn_bottom"] = 0,
}

---@type string[]
local waypoint_names = {
    "waypoint_top_left",
    "waypoint_top",
    "waypoint_top_right",
    "waypoint_left",
    "waypoint_middle",
    "waypoint_right",
    "waypoint_bottom_left",
    "waypoint_bottom_right",
}


local on_init = function()
    -- We pull out all the named areas and points from the scenario right from the start
    -- That way we can save them and also we check they exist :)

    global.spawn_areas = {}
    global.spawn_area_weights = {}
    global.waypoints = {}
    global.tracked_command_units = {}
    global.tracked_destroyed_units = {}

    local surface = game.surfaces['nauvis']

    for key, value in pairs(spawn_area_name_weights) do
        local sa = surface.get_script_area(key)
        if sa == nil then error("Could not find spawn area " .. key) end
        global.spawn_areas[key] = sa
        global.spawn_area_weights[sa] = value
    end

    for _, value in pairs(waypoint_names) do
        local sp = surface.get_script_position(value)
        if sp == nil then error("Could not find script position " .. value) end
        global.waypoints[value] = sp
    end

    local sp = game.get_entity_by_tag("spaceship")
    if sp == nil then error ("Could not find spaceship in map") end
    global.spaceship = sp
end


---@type table<ScriptArea|ScriptPosition, fun():ScriptPosition|nil>
local pathfinding_table = nil -- singleton for the function below
---@param from ScriptArea|ScriptPosition
---@return ScriptPosition|nil
local function get_next_waypoint(from)
    if pathfinding_table == nil then   
        pathfinding_table = {
            [global.waypoints.waypoint_top_left]     = function() return global.waypoints.waypoint_left end,
            [global.waypoints.waypoint_top]          = function() return global.waypoints.waypoint_middle end,
            [global.waypoints.waypoint_top_right]    = function() return global.waypoints.waypoint_top_right end,
            [global.waypoints.waypoint_left]         = function() return global.waypoints.waypoint_bottom_left end,
            [global.waypoints.waypoint_middle]       = function() return ((math.random(0,1) == 0) and {global.waypoints.waypoint_left} or {global.waypoints.waypoint_right})[1] end,
            [global.waypoints.waypoint_right]        = function() return global.waypoints.waypoint_bottom_right end,
            [global.waypoints.waypoint_bottom_left]  = function() return nil end,
            [global.waypoints.waypoint_bottom_right] = function() return nil end,
            [global.spawn_areas.spawn_top_left]      = function() return global.waypoints.waypoint_top_left end,
            [global.spawn_areas.spawn_top]           = function() return global.waypoints.waypoint_top end,
            [global.spawn_areas.spawn_top_right]     = function() return global.waypoints.waypoint_top_right end,
            [global.spawn_areas.spawn_middle_1]      = function() return global.waypoints.waypoint_middle end,
            [global.spawn_areas.spawn_middle_2]      = function() return global.waypoints.waypoint_middle end,
            [global.spawn_areas.spawn_left]          = function() return global.waypoints.waypoint_left end,
            [global.spawn_areas.spawn_right]         = function() return global.waypoints.waypoint_right end,
            [global.spawn_areas.spawn_bottom_left]   = function() return global.waypoints.waypoint_bottom_left end,
            [global.spawn_areas.spawn_bottom_right]  = function() return global.waypoints.waypoint_bottom_right end,
            [global.spawn_areas.spawn_bottom]        = function() return nil end,
        }
    end
    return pathfinding_table[from]()
end

---@param waypoint ScriptPosition?
---@param entity LuaEntity
local function set_command_based_on_target_waypoint(entity, waypoint) 
    if waypoint == nil then
        entity.set_command {
            type = defines.command.attack,
            target = global.spaceship,
            pathfind_flags = pathfinding_flags
        }

    else -- we know its a waypoint
        entity.set_command{
            type = defines.command.go_to_location,
            distraction = defines.distraction.none,
            pathfind_flags = pathfinding_flags,
            destination = waypoint.position,
            radius = 1
        } 
    end
end

---@param ScriptArea ScriptArea
---@param number uint32
---@return MapPosition[]
local function generate_spawnpoints_from_area(ScriptArea, number)
    ---@type MapPosition[]
    local r = {}
    for i = 1, number do
        r[i] = { 
            x = ScriptArea.area.left_top.x + math.random()*(ScriptArea.area.right_bottom.x - ScriptArea.area.left_top.x),
            y = ScriptArea.area.left_top.y + math.random()*(ScriptArea.area.right_bottom.y - ScriptArea.area.left_top.y)
        }
    end
    return r
end

---@param per_group_unit_count uint
local spawn_wave = function (per_group_unit_count)
    local surface = game.surfaces['nauvis']

    -- For each spawn area
    -- Generate "per_group_unit_count" amount of spawn points in that area
    -- for each of those spawn points
    -- spawn a biter and add it to tracked units and register on death event call back

    for _, spawn_area in pairs(global.spawn_areas) do

        local spawns = generate_spawnpoints_from_area(
            spawn_area, 
            math.ceil(per_group_unit_count*global.spawn_area_weights[spawn_area]))

        local target_waypoint = get_next_waypoint(spawn_area)

        for _, spawn in ipairs(spawns) do
            local entity = surface.create_entity {name="small-biter", position = spawn, force="enemy"}

            if entity ~= nil then
                local registration_number = script.register_on_entity_destroyed(entity)
                set_command_based_on_target_waypoint(entity, target_waypoint)            
                global.tracked_command_units[entity.unit_number] = {entity = entity, current_target = target_waypoint}
                global.tracked_destroyed_units[registration_number] = entity.unit_number
            else
                -- else the spawn failed, but we can't do much about that right now
                error("Failed to spawn unit")
            end            
        end
    end
end

---@param event EventData.on_entity_destroyed
local on_entity_destroyed = function(event)
    -- There are two kinds of destruction events we care about, the spaceship and biters
    if (global.spaceship ~= nil) then 
    end
end

---@param event EventData.on_ai_command_completed
local on_ai_command_completed = function(event)
    local tracking_data = global.tracked_command_units[event.unit_number]
    local completed_target = tracking_data.current_target
    local next_target = get_next_waypoint(completed_target)

    set_command_based_on_target_waypoint(tracking_data.entity, next_target)
    tracking_data.current_target = next_target
    print("hi")
end


local waves = {
    events = { 
      [defines.events.on_entity_destroyed] = on_entity_destroyed,
      [defines.events.on_ai_command_completed] = on_ai_command_completed
    },
    on_init = on_init,
    spawn_wave = spawn_wave
}
return waves