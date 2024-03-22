local waves = require("control/waves")
local force_management = require("control/force_management")

local STATE_WAITING_TO_START = 0
local STATE_SPAWNING_WAVE = 1
local STATE_WAITING_BETWEEN_WAVES = 2
local BETWEEN_WAVES_WAIT_TIME_IN_SECONDS = 5
local WAVE_TIME_OUT_IN_SECONDS = 180

-- Every second we roll
local on_60_tick = function()
    if global.game_master.state == STATE_WAITING_TO_START then
        -- dumb delay for now, wait for players to join
        if game.tick > 120 then
            global.game_master.state = STATE_WAITING_BETWEEN_WAVES 
        end
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
                -- IF all biters are gone, or we have waited the timeout additional time, 

                print("transition")
                -- payout cash and transition 
            end

        end


        return
    elseif global.game_master.state == STATE_WAITING_BETWEEN_WAVES then
        return 
    end

    -- waves.spawn_wave(2)
    -- force_management.give_coins_to_all_players(400)
    -- force_management.distribute_coins_between_players(1000)
end

local load_wave_data = function()
    -- Would love to somehow throw this into the data stage :/
    -- We do this in reverse order, because its easier to pop the end of an array :)
    global.game_master.waves = {
        {
            title = "Wave 4 - Medium spitters",
            enemy = "medium-spitter", 
            amount = 6, 
            tick_delay = 120,
            reward_flat = 50,
            reward_divided = 200
        },
        {
            title = "Wave 3 - Medium biters",
            enemy = "medium-biter", 
            amount = 6, 
            tick_delay = 120,
            reward_flat = 50,
            reward_divided = 200
        },
        {
            title = "Wave 2 - Small spitters",
            enemy = "small-spitter", 
            amount = 10, 
            tick_delay = 60,
            reward_flat = 50,
            reward_divided = 200
        },
        {
            title = "Wave 1 - Small biters",
            enemy = "small-biter", 
            amount = 10, 
            tick_delay = 60,
            reward_flat = 50,
            reward_divided = 200
        },
    }
end

local on_init = function()
    global.game_master = {}
    global.game_master.state = STATE_WAITING_TO_START
    global.game_master.state_mem = nil
    global.game_master.running = false
    load_wave_data()
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

