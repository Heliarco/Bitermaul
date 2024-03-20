local waves = require("waves")

local on_60_tick = function()
    waves.spawn_wave(2)
end

local game_master = {
    on_nth_tick = {
        [60] = on_60_tick
    },
    events = {

    }

}
return game_master