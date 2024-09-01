-- Okay so, we are running a HEAVILY orchestrated game
-- Its not a free running sandbox, but instead events are happening one after the other.
-- We call this waves.

-- A wave starts with a bit of grace timer as well as an announcement of what is coming.
-- Along this announcement is a bit of cash, for creating some equipment
-- A wave lasts until all the enemies are killed, and then a small wind down timer to catch our breath.
-- We repeat this forever (or until we run out of waves.)

-- Before the first wave, we are in a lobby state, allowing players to join etc.
-- Once All players "press ready", the game locks in, initial cash is distributed and an extra long start timer is run to allow for initial defense build


local waves = require("control/waves")
local console_commands = require("control/console_commands")
local money_distributer = require("control/services/money_distributer")
local game_script = require("env/game_script")


local STATE_WAITING_TO_START = 0
local STATE_INITIAL_GRACE_PERIOD = 1
local STATE_RUNNING_WAVE = 2
local STATE_WAITING_BETWEEN_WAVES = 3



---@param seconds uint
local announce_time_left = function(seconds)
    game.print({"announcer-spawn-time-left", seconds},{r = 0.8, g = 0.1, b = 0.1, a = 1})
end

local announce_enemies_left = function()
    game.print({"announcer-enemies-left", global.waves.enemies_left})
end

local state_cfg = {} -- Forward declaration
local find_state_info = function(state)
    for _, v in pairs(state_cfg) do
        if v.id == state then
            return v
        end
    end
end

-- Honestly just here to remember to always set them in pairs :D
local change_to_state = function(state)
    local state_details = find_state_info(state)
    global.game_master.state = state
    global.game_master.state_mem = state_details.init()
end



state_cfg = {
    {
        id = STATE_WAITING_TO_START,
        initial_mem = {},
        init = function() end,
        step = function(mem)
            -- Do a ready check here at some point
            change_to_state(STATE_INITIAL_GRACE_PERIOD)
        end
    },
    {
        id = STATE_INITIAL_GRACE_PERIOD,
        init = function() 
            money_distributer.distribute_coins(game_script.start_coins)
            return {
                time_left = game_script.initial_grace_period_in_seconds
            }
        end,
        step = function(mem)
            if mem.time_left <= 0 then
                change_to_state(STATE_RUNNING_WAVE)
            end
            announce_time_left(mem.time_left)
            mem.time_left = mem.time_left - 1
        end
    },
    {
        id = STATE_RUNNING_WAVE,
        init = function()
            global.game_master.current_wave_number = global.game_master.current_wave_number + 1
            local wave_number = global.game_master.current_wave_number
            waves.start_spawning_wave(wave_number)
            return {}
         end,
        step = function(mem)
            
        end
    },
    {
        id = STATE_WAITING_BETWEEN_WAVES,
        init = function() 
            return {
                time_left = game_script.time_between_waves_in_seconds
            }
        end,
        step = function(mem)

        end
    }
}








-- Every second we roll
local on_60_tick = function()
    -- We basically "tick" the state machine here.
    local state_info = find_state_info(global.game_master.state)
    state_info.step(global.game_master.state_mem)
end


local on_init = function()
    change_to_state(STATE_WAITING_TO_START)
end

local game_master = {
    on_nth_tick = {
        [60] = on_60_tick
    },
    events = {

    },
    on_init = on_init
}
return game_master

