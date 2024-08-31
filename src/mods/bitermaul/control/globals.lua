--- Honestly we are going to rely a hell of a lot on the globals for storing state.
--- Yea yea i know about coupling etc. but we are not doing enterprise stuff

--- We init them here and add comments as needed, 
--- but you would not need to require this file directly since globals are always available
--- 
--- We will usually have an entry per module, signifying ownership

local on_init = function()
    global.waves = {

        --- public: 
        
        is_spawning_wave = false,
        bounty = 1, -- How much we pay per kill

        --- private:
        
        --- Pathfinding information, it is pulled from the map during init
        --- More data is calculated and added for faster pathfinding
        spawn_areas = {},
        spawn_area_weights = {},
        waypoints = {},
        
        --- Once units are spawned we need to keep track of them.
        --- For paying out death rewards and to handle pathfinding
        tracked_command_units = {},
        tracked_destroyed_units = {},
        
    
        --- Information used to keep track of the currently spawning wave.
        --- The waves module is instructed to spawn a wave and does all the logic for that in its own tick method
        currently_spawning_wave = {},
        currently_spawning_wave_ticks_since_last = 0,
        currently_spawning_wave_batches_left = 0,
        
        
        --- Will point to spaceship entity
        spaceship = nil,
        spaceship_d_reg = nil -- Destroyed registry
    }
    global.game_master = {

    }






    global.surface = game.surfaces['nauvis']







end



local globals = {
    on_init = on_init,
   
}

return globals