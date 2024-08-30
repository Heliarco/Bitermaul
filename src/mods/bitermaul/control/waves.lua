--- The brains behind the enemy forces.

--- start_spawning_wave (wave_index)
--- global.is_spawning_wave, boolean -- used / monitored by game master


-- WE HANDLE BOUNTY PAYOUT


local command_attempts_berserk_limit = 100

-- Return object for later, but we need a forward declaration
local waves = {}
local surface

--- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! INITIALIZING LOGIC. SETTING UP WAYPOINTS, SPAWN ZONES ETC.
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
    ["spawn_top_left"] = 1,
    ["spawn_top"] = 1,
    ["spawn_top_right"] = 1,
    ["spawn_middle_1"] = 0.5,
    ["spawn_middle_2"] = 0.5,
    ["spawn_left"] = 1,
    ["spawn_right"] = 1,
    ["spawn_bottom_left"] = 1,
    ["spawn_bottom_right"] = 1,
    ["spawn_bottom"] = 1
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

    global.currently_spawning_wave = {}
    global.currently_spawning_wave_ticks_since_last = 0
    global.currently_spawning_wave_batches_left = 0

    surface = game.surfaces['nauvis']

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
    global.spaceship_d_reg = script.register_on_entity_destroyed(sp)
end

--- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! PATHFINDING HELPERS

---@type table<ScriptArea|ScriptPosition, fun():ScriptPosition|nil>
local pathfinding_table = nil -- singleton for the function below
---@param from ScriptArea|ScriptPosition
---@return ScriptPosition|nil
local function get_next_waypoint(from)
    if pathfinding_table == nil then   
        pathfinding_table = {
            [global.waypoints.waypoint_top_left]     = function() return global.waypoints.waypoint_left end,
            [global.waypoints.waypoint_top]          = function() return global.waypoints.waypoint_middle end,
            [global.waypoints.waypoint_top_right]    = function() return global.waypoints.waypoint_right end,
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

---@param entity LuaEntity
local function set_fallback_action(entity) -- go berserk
    local random_name = waypoint_names[math.random(#waypoint_names)]
    local random_waypoint = global.waypoints[random_name]
    entity.set_command({
            type = defines.command.go_to_location,
            distraction = defines.distraction.by_anything,
            pathfind_flags = pathfinding_flags,
            destination = random_waypoint.position,
            radius = 1
        } 
    )
end

---@param waypoint ScriptPosition?
---@param entity LuaEntity
local function set_command_based_on_target_waypoint(entity, waypoint) 
    if waypoint == nil then
        if global.spaceship ~= nil then
            entity.set_command {
                type = defines.command.attack,
                target = global.spaceship,
                pathfind_flags = pathfinding_flags
            }
        else
            set_fallback_action(entity)
        end
    else -- we know its a waypoint
        entity.set_command{
            type = defines.command.go_to_location,
                 pathfind_flags = pathfinding_flags,
            destination = waypoint.position,
            radius = 1
        } 
    end
end


--- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! SPAWNING
--- start_spawning_wave (wave_index)
--- is_spawning_wave, boolean -- used / monitored by game master



---@param wave_index number
local start_spawning_wave = function (wave_index)

    if global.is_spawning_wave then
        return false -- Aint doing shit then
    end

    local game_script_data = require("../env/game_script")
    
    global.currently_spawning_wave = game_script_data.waves[wave_index]
    global.is_spawning_wave = true
    global.currently_spawning_wave_ticks_since_last = 0
    global.currently_spawning_wave_batches_left = global.currently_spawning_wave.batches

    return true
end

--- Will try to find "number" of free spawn positions in an area
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





local on_tick = function()
    -- every tick
    
    if not global.is_spawning_wave then
        return -- Obvious
    end
    
    -- If not time to spawn, increment counter and return
    if global.currently_spawning_wave_batch == 0 then
        global.is_spawning_wave = false -- We are done
        return
    end

    if global.currently_spawning_wave.delay_between_batches > global.currently_spawning_wave_ticks_since_last then
        global.currently_spawning_wave_ticks_since_last = global.currently_spawning_wave_ticks_since_last + 1 
        return
    end

    -- Some quick book keeping so we know how long time left / how many batches left
    global.currently_spawning_wave_batches_left = global.currently_spawning_wave_batches_left - 1
    global.currently_spawning_wave_ticks_since_last = 0
    
    -- We are spawning and its time for next batch:
    for _, spawn_area in pairs(global.spawn_areas) do
        -- For each spawn area, find /generate the exact locations needed to spawn enemies
        local spawns = generate_spawnpoints_from_area(
            spawn_area, 
            math.ceil(global.currently_spawning_wave.amount_pr_batch*spawn_area))
        
        -- And their routing info
        local target_waypoint = get_next_waypoint(spawn_area)
    
        -- Now spawn them and set their command
        for _, spawn in ipairs(spawns) do
            local entity = surface.create_entity {name=global.currently_spawning_wave.enemy_name, position = spawn, force="enemy"}

            if entity ~= nil then
                local registration_number = script.register_on_entity_destroyed(entity)         
                set_command_based_on_target_waypoint(entity, target_waypoint)
                
                --- Save information about the enemy we just spawned.
                --- We have registered its creation, so we need to keep track of it!
                global.tracked_command_units[entity.unit_number] = {
                    entity = entity, 
                    current_target = target_waypoint, 
                    attempts = 0
                }
                global.tracked_destroyed_units[registration_number] = entity.unit_number
            else
                -- else the spawn failed, but we can't do much about that right now
                error("Failed to spawn unit")
            end            
        end
    end    
end


--- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! WAVE TRACKING

---@param event EventData.on_entity_destroyed
local on_entity_destroyed = function(event)
    -- There are two kinds of destruction events we care about, the spaceship and biters
    if global.spaceship_d_reg == event.registration_number then
        global.spaceship_d_reg = nil
        global.spaceship = nil
    else
        global.tracked_command_units[event.unit_number] = nil
        global.tracked_destroyed_units[event.registration_number] = nil
    end
end

---@param event EventData.on_ai_command_completed
local on_ai_command_completed = function(event)

    local tracking_data = global.tracked_command_units[event.unit_number]

    if event.result == defines.behavior_result.success then
        local completed_target = tracking_data.current_target
        if completed_target == nil then
            set_fallback_action(tracking_data.entity)
        else
            local next_target = get_next_waypoint(completed_target)   
            set_command_based_on_target_waypoint(tracking_data.entity, next_target)
            tracking_data.current_target = next_target
        end

    elseif event.result == defines.behavior_result.deleted then
        print("hi")
    elseif event.result == defines.behavior_result.fail then
        local attempts = tracking_data.attempts
        if attempts < command_attempts_berserk_limit then
            tracking_data.attempts = tracking_data.attempts + 1
            set_command_based_on_target_waypoint(tracking_data.entity, tracking_data.current_target)
        else
            set_fallback_action(tracking_data.entity)
        end
    elseif event.result == defines.behavior_result.in_progress then
        print("hi")
    else
        print("no ?")
    end
end


waves = {
    on_nth_tick = {
        [60] = on_tick
    },
    events = { 
      [defines.events.on_entity_destroyed] = on_entity_destroyed,
      [defines.events.on_ai_command_completed] = on_ai_command_completed
    },
    on_init = on_init,
    start_spawning_wave = start_spawning_wave
}
return waves