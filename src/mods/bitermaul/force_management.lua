-- We got two jobs here
-- First we setup the force relationshipts to eachother
-- Second, we handle assigning joining players to forces as they join

local maul_player_forces = { -- The order here is also the order of player assignment
    "Bottom", "BottomLeft" , "BottomRight", "Middle","Left",  "Right" , "TopLeft", "Top", "TopRight"
}

-- Set every one to have a ceasefire but not be friends
local on_init = function()
    for _, source_force_name in ipairs(maul_player_forces) do
        for _, target_force_name in ipairs(maul_player_forces) do
            if not (source_force_name == target_force_name) then
                local source_force = game.forces[source_force_name]
                local target_force = game.forces[target_force_name]
                source_force.set_friend(target_force, false)
                source_force.set_cease_fire(target_force, true)
            end
        end
    end
end

---@param event EventData.on_player_joined_game
local on_player_joined_game = function(event)
    local player = game.players[event.player_index]
    local force_name = maul_player_forces[player.index]
    local force = game.forces[force_name]
    player.force = force
    local spawn_position = force.get_spawn_position("nauvis")
    player.character.teleport(spawn_position)
end

-- Attempts to refresh scouted terrain every 60th tick, so we can remove fog of war
local on_60_tick = function()
    for _, force in pairs(game.forces) do
        force.chart_all()
    end 
end

force_management = {
    on_nth_tick = {
        [60] = on_60_tick
    },
    events = {
        [defines.events.on_player_joined_game] = on_player_joined_game,
    },
    on_init = on_init
}

return force_management