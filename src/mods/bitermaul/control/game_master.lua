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

local STATE_WAITING_TO_START = 0
local STATE_SPAWNING_WAVE = 1
local STATE_WAITING_BETWEEN_WAVES = 2
local BETWEEN_WAVES_WAIT_TIME_IN_SECONDS = 5


---@param seconds uint
local announce_time_left = function(seconds)
    game.print({"spawn-time-left", seconds},{r = 0.8, g = 0.1, b = 0.1, a = 1})
end




-- Every second we roll
local on_60_tick = function()
    if global.game_master.state == STATE_WAITING_TO_START then
        -- Insert some delay mechanism here
        global.game_master.state = STATE_WAITING_BETWEEN_WAVES 
        global.game_master.state_mem = nil
    
        return -- Nothing to do yet, let the people join


    elseif global.game_master.state == STATE_SPAWNING_WAVE then
        -- If we just got here, global.game_master.state_mem should be nil 
        if global.game_master.state_mem == nil then
            -- pull wave data for next wave and initialize memory
            local wave_info = table.remove(global.game_master.waves)
            wave_info.last_unit_spawned_tick = game.tick
            global.game_master.state_mem = wave_info
        end
        -- Make sure to stagger units by their delay value
        if global.game_master.state_mem.last_unit_spawned_tick + global.game_master.state_mem.tick_delay < game.tick then
            if global.game_master.state_mem.amount > 0 then
                -- Time to spawn a wave
                global.game_master.state_mem.last_unit_spawned_tick = game.tick
                waves.spawn_wave(1, global.game_master.state_mem.enemy)
                global.game_master.state_mem.amount = global.game_master.state_mem.amount - 1
            else 
                local should_transition = false
                -- IF all biters are gone, or we have waited the timeout additional time, 


                if should_transition then
                    payout_rewards()
                    global.game_master.state = STATE_WAITING_BETWEEN_WAVES 
                    global.game_master.state_mem = nil
                end

                -- payout cash and transition 
            end

        end
        return


    -- Just a nice little countdown between waves :)
    elseif global.game_master.state == STATE_WAITING_BETWEEN_WAVES then
        if global.game_master.state_mem == nil then
            -- First cycle here
            global.game_master.state_mem = {
                seconds_left = BETWEEN_WAVES_WAIT_TIME_IN_SECONDS
            }
        end
        -- We KNOW we only get a tick every second, so that makes time keeping easy here
        announce_time_left(global.game_master.state_mem.seconds_left)
        global.game_master.state_mem.seconds_left = global.game_master.state_mem.seconds_left - 1
        if global.game_master.state_mem.seconds_left < 0.5 then -- no seconds left
            global.game_master.state = STATE_SPAWNING_WAVE 
            global.game_master.state_mem = nil
        end
        return 
    end
end


local on_init = function()
    global.game_master = {}
    global.game_master.state = STATE_WAITING_TO_START
    global.game_master.state_mem = nil
    global.game_master.running = false
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

