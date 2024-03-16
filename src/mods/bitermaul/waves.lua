waves = {}

-- /c    local s = game.surfaces['nauvis'] local p = {0,0} s.create_entity{name = "big-biter", position = p, force = game.forces['enemy']}
-- https://lua-api.factorio.com/latest/classes/LuaUnitGroup.html

-- what we want to work with here is called LuaUnitGroups
-- how to get areas

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

-- After initialization, these are populated
---@type table<string, ScriptArea>
local spawn_areas = {}
---@type table<ScriptArea, number>
local spawn_area_weights = {}
---@type table<string, ScriptPosition>
local waypoints = {} 
---@type LuaSurface
local surface = nil
---@type LuaEntity
local spaceship = nil

---@return nil
local function extract_map_data()
    surface = game.surfaces['nauvis']
    -- We pull out all the named areas and points from the scenario right from the start
    -- That way we can save them and also we check they exist :)
    for key, value in pairs(spawn_area_name_weights) do
        local sa = surface.get_script_area(key)
        if sa == nil then error("Could not find spawn area " .. key) end
        spawn_areas[key] = sa
        spawn_area_weights[sa] = value
    end
    
    for _, value in pairs(waypoint_names) do
        local sp = surface.get_script_position(value)
        if sp == nil then error("Could not find script position " .. value) end
        waypoints[value] = sp
    end
    
    local sp = game.get_entity_by_tag("spaceship")
    if sp == nil then error ("Could not find spaceship in map") end
    spaceship = sp
end


----@type table<ScriptArea|ScriptPosition, fun():ScriptPosition|nil>
---@type table<string, fun():ScriptPosition|nil>
local get_next_waypoint_switch = {}
local function populate_pathfinding_data()
    get_next_waypoint_switch = {
        [waypoints.waypoint_top_left.name]     = function() return waypoints.waypoint_left end,
        [waypoints.waypoint_top.name]          = function() return waypoints.waypoint_middle end,
        [waypoints.waypoint_top_right.name]    = function() return waypoints.waypoint_top_right end,
        [waypoints.waypoint_left.name]         = function() return waypoints.bottom_left end,
        [waypoints.waypoint_middle.name]       = function() return ((math.random(0,1) == 0) and {waypoints.waypoint_left} or {waypoints.waypoint_right})[1] end,
        [waypoints.waypoint_right.name]        = function() return waypoints.waypoint_bottom_right end,
        [waypoints.waypoint_bottom_left.name]  = function() return nil end,
        [waypoints.waypoint_bottom_right.name] = function() return nil end,
        [spawn_areas.spawn_top_left.name]      = function() return waypoints.waypoint_top_left end,
        [spawn_areas.spawn_top.name]           = function() return waypoints.waypoint_top end,
        [spawn_areas.spawn_top_right.name]     = function() return waypoints.waypoint_top_right end,
        [spawn_areas.spawn_middle_1.name]      = function() return waypoints.waypoint_middle end,
        [spawn_areas.spawn_middle_2.name]      = function() return waypoints.waypoint_middle end,
        [spawn_areas.spawn_left.name]          = function() return waypoints.waypoint_left end,
        [spawn_areas.spawn_right.name]         = function() return waypoints.waypoint_right end,
        [spawn_areas.spawn_bottom_left.name]   = function() return waypoints.waypoint_bottom_left end,
        [spawn_areas.spawn_bottom_right.name]  = function() return waypoints.waypoint_bottom_right end,
        [spawn_areas.spawn_bottom.name]        = function() return nil end,
    }
end

---@return nil
function waves.oninit()
    extract_map_data()
    populate_pathfinding_data()
end







---@param waypoint ScriptPosition?
local function set_command_based_on_target_waypoint(entity, waypoint) 
    if waypoint == nil then
        entity.set_command {
            type = defines.command.attack,
            target = spaceship,
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

-- unit number -> entity & current target
--- @alias EntityGoalTracking {entity: LuaEntity, current_target: ScriptPosition|nil}
---@type table<uint32, EntityGoalTracking>
local tracked_units = {}

-- destruction reg number -> unit_number
---@type table<integer, uint32>
local tracked_destroyed_units = {}


---@param per_group_unit_count uint
function waves.spawn_wave(per_group_unit_count)
    -- For each spawn area
    -- Generate "per_group_unit_count" amount of spawn points in that area
    -- for each of those spawn points
    -- spawn a biter and add it to tracked units and register on death event call back

    for _, spawn_area in pairs(spawn_areas) do

        local spawns = generate_spawnpoints_from_area(
            spawn_area, 
            math.ceil(per_group_unit_count*spawn_area_weights[spawn_area]))

        local target_waypoint = get_next_waypoint_switch[spawn_area.name]()

        for spawn_index, spawn in ipairs(spawns) do
            local entity = surface.create_entity {name="small-biter", position = spawn, force="enemy"}

            if entity ~= nil then
                set_command_based_on_target_waypoint(entity, target_waypoint)
                tracked_units[entity.unit_number] = {entity = entity, current_target = target_waypoint}
                local registration_number = script.register_on_entity_destroyed(entity)
                tracked_destroyed_units[registration_number] = entity.unit_number
            else
                -- else the spawn failed, bu we can't do much about that right now
                error("Failed to spawn unit")
            end            
        end
    end
end

---@param event EventData.on_entity_destroyed
function waves.on_entity_destroyed(event)
    -- There are two kinds of destruction events we care about, the spaceship and biters
    if (spaceship ~= nil) then 
    end
end

---@param event EventData.on_ai_command_completed
function waves.on_ai_command_completed(event)
    local tracking_data = tracked_units[event.unit_number]
    local completed_target = tracking_data.current_target
    local next_target = get_next_waypoint_switch[completed_target.name]()

    set_command_based_on_target_waypoint(tracking_data.entity, next_target)
    tracking_data.current_target = next_target
    print("hi")
end