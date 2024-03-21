local waves = require("waves")
local force_management = require("force_management")

local on_60_tick = function()
    waves.spawn_wave(2)
    force_management.give_coins_to_all_players(400)
    force_management.distribute_coins_between_players(1000)
end

local game_master = {
    on_nth_tick = {
        [60] = on_60_tick
    },
    events = {

    }

}
return game_master

