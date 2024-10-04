--- The brains behind the enemy forces.
--- Does anyhting related to pathing etc.
--- Also Handles paying out wave rewards and bounties

--- start_spawning_wave (wave_index)

local game_script_data = require("env/game_script")
local money_distributer = require("control/services/money_distributer")
local command_attempts_berserk_limit = 100
local table_helpers = require("libs/table_helpers")

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

local maul_player_forces = { -- The order here is also the order of player assignment
    "Bottom", "BottomLeft" , "BottomRight", "Middle","Left",  "Right" , "TopLeft", "Top", "TopRight"
}




local on_init = function()
    -- We pull out all the named areas and points from the scenario right from the start
    -- That way we can save them and also we check they exist :)
    local surface = global.surface


    for key, value in pairs(spawn_area_name_weights) do
        local sa = surface.get_script_area(key)
        if sa == nil then error("Could not find spawn area " .. key) end
        global.waves.spawn_areas[key] = sa
        global.waves.spawn_area_weights[sa] = value
    end

    for _, value in pairs(waypoint_names) do
        local sp = surface.get_script_position(value)
        if sp == nil then error("Could not find script position " .. value) end
        global.waves.waypoints[value] = sp
    end

    local sp = game.get_entity_by_tag("spaceship")
    if sp == nil then error ("Could not find spaceship in map") end
    global.waves.spaceship = sp
    global.waves.spaceship_d_reg = script.register_on_entity_destroyed(sp)
end

--- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! PATHFINDING HELPERS

---@type table<ScriptArea|ScriptPosition, fun():ScriptPosition|nil>
local pathfinding_table = nil -- singleton for the function below
---@param from ScriptArea|ScriptPosition
---@return ScriptPosition|nil
local function get_next_waypoint(from)
    if pathfinding_table == nil then   
        pathfinding_table = {
            [global.waves.waypoints.waypoint_top_left]     = function() return global.waves.waypoints.waypoint_left end,
            [global.waves.waypoints.waypoint_top]          = function() return global.waves.waypoints.waypoint_middle end,
            [global.waves.waypoints.waypoint_top_right]    = function() return global.waves.waypoints.waypoint_right end,
            [global.waves.waypoints.waypoint_left]         = function() return global.waves.waypoints.waypoint_bottom_left end,
            [global.waves.waypoints.waypoint_middle]       = function() return ((math.random(0,1) == 0) and {global.waves.waypoints.waypoint_left} or {global.waves.waypoints.waypoint_right})[1] end,
            [global.waves.waypoints.waypoint_right]        = function() return global.waves.waypoints.waypoint_bottom_right end,
            [global.waves.waypoints.waypoint_bottom_left]  = function() return nil end,
            [global.waves.waypoints.waypoint_bottom_right] = function() return nil end,
            [global.waves.spawn_areas.spawn_top_left]      = function() return global.waves.waypoints.waypoint_top_left end,
            [global.waves.spawn_areas.spawn_top]           = function() return global.waves.waypoints.waypoint_top end,
            [global.waves.spawn_areas.spawn_top_right]     = function() return global.waves.waypoints.waypoint_top_right end,
            [global.waves.spawn_areas.spawn_middle_1]      = function() return global.waves.waypoints.waypoint_middle end,
            [global.waves.spawn_areas.spawn_middle_2]      = function() return global.waves.waypoints.waypoint_middle end,
            [global.waves.spawn_areas.spawn_left]          = function() return global.waves.waypoints.waypoint_left end,
            [global.waves.spawn_areas.spawn_right]         = function() return global.waves.waypoints.waypoint_right end,
            [global.waves.spawn_areas.spawn_bottom_left]   = function() return global.waves.waypoints.waypoint_bottom_left end,
            [global.waves.spawn_areas.spawn_bottom_right]  = function() return global.waves.waypoints.waypoint_bottom_right end,
            [global.waves.spawn_areas.spawn_bottom]        = function() return nil end,
        }
    end
    return pathfinding_table[from]()
end

---@param entity LuaEntity
local function set_fallback_action(entity) -- go berserk
    local random_name = waypoint_names[math.random(#waypoint_names)]
    local random_waypoint = global.waves.waypoints[random_name]
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
        if global.waves.spaceship ~= nil then
            entity.set_command {
                type = defines.command.attack,
                target = global.waves.spaceship,
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

    if global.waves.is_running_wave then
        return false -- Aint doing shit then
    end


    global.waves.currently_spawning_wave = game_script_data.waves[wave_index]
    global.waves.is_running_wave = true
    global.waves.currently_spawning_wave_ticks_since_last = 0
    global.waves.currently_spawning_wave_batches_left = global.waves.currently_spawning_wave.batches
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

local update_enemies_left = function()
    global.waves.enemies_left = table_helpers.tablelength(global.waves.tracked_destroyed_units)
end


local on_tick = function()
    -- every tick
    
    if not global.waves.is_running_wave then
        return -- Obvious
    end

    update_enemies_left()

    -- Check if we are _COMPLETELY_ done with the current wave
    if global.waves.currently_spawning_wave_batches_left == 0 then
        if global.waves.enemies_left == 0 then
            money_distributer.distribute_coins(global.waves.currently_spawning_wave.coins)
            global.waves.is_running_wave = false -- We are done
            return
        end
    end
    
    -- If not time to spawn, increment counter and return
    if global.waves.currently_spawning_wave.delay_between_batches > global.waves.currently_spawning_wave_ticks_since_last then
        global.waves.currently_spawning_wave_ticks_since_last = global.waves.currently_spawning_wave_ticks_since_last + 1 
        return
    end

    -- Some quick book keeping so we know how long time left / how many batches left
    global.waves.currently_spawning_wave_batches_left = global.waves.currently_spawning_wave_batches_left - 1
    global.waves.currently_spawning_wave_ticks_since_last = 0
    
    -- We are spawning and its time for next batch:
    for _, spawn_area in pairs(global.waves.spawn_areas) do
        -- For each spawn area, find /generate the exact locations needed to spawn enemies
        
        local spawns = generate_spawnpoints_from_area(
            spawn_area, 
            math.ceil(global.waves.currently_spawning_wave.amount_pr_batch*spawn_area))
        
        -- And their routing info
        local target_waypoint = get_next_waypoint(spawn_area)
    
        -- Now spawn them and set their command
        for _, spawn in ipairs(spawns) do
            local entity = surface.create_entity {name=global.waves.currently_spawning_wave.enemy_name, position = spawn, force="enemy"}

            if entity ~= nil then
                local registration_number = script.register_on_entity_destroyed(entity)         
                set_command_based_on_target_waypoint(entity, target_waypoint)
                
                --- Save information about the enemy we just spawned.
                --- We have registered its creation, so we need to keep track of it!
                global.waves.tracks[entity.unit_number] = {
                    entity = entity, 
                    current_target = target_waypoint, 
                    attempts = 0
                }
                global.waves.tracked_destroyed_units[registration_number] = entity.unit_number
            else
                -- else the spawn failed, but we can't do much about that right now
                error("Failed to spawn unit")
            end            
        end
    end    
end


--- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! WAVE TRACKING
--- On entity destroyed and died are different events.
--- Died is for a proper _DEATH_ aka, killed by something.
--- Destroyed implies "removed" for any reason. This is the Thorough one.
--- We use "destroyed" for managing internal tracking state
--- We use "died" for bounty payout

----@param event EventData.on_entity_died
local on_entity_died = function(event)
    --- If an enemy died and one of our forces did the killing, we pay out the bounty
    if event.entity.force.name == "enemy" then
        local killing_force = event.force
        local killing_force_name = killing_force.name

        if table_helpers.table_contains(maul_player_forces, killing_force_name) then
            money_distributer.distribute_coins_to_force(global.waves.bounty, killing_force_name)
        end
    end
end 


---@param event EventData.on_entity_destroyed
local on_entity_destroyed = function(event)
    -- There are two kinds of destruction events we care about, the spaceship and biters
    if global.waves.spaceship_d_reg == event.registration_number then
        global.waves.spaceship_d_reg = nil
        global.waves.spaceship = nil
    else
        -- Is it an enemy tracked by US?
        if global.waves.tracked_destroyed_units[event.registration_number] ~= nil then
            -- Stop tracking it. Its dead Jim
            global.waves.tracked_command_units[event.unit_number] = nil
            global.waves.tracked_destroyed_units[event.registration_number] = nil
        end
    end
end

---@param event EventData.on_ai_command_completed
local on_ai_command_completed = function(event)

    local tracking_data = global.waves.tracked_command_units[event.unit_number]

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
      [defines.events.on_entity_died] = on_entity_died,
      [defines.events.on_entity_destroyed] = on_entity_destroyed,
      [defines.events.on_ai_command_completed] = on_ai_command_completed
    },
    on_init = on_init,
    start_spawning_wave = start_spawning_wave
}
return waves