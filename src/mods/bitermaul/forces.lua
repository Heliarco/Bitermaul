-- We got two jobs here
-- First we setup the force relationshipts to eachother
-- Second, we handle assigning joining players to forces as they join

local forces = {
    "TopLeft", "Top", "TopRight", "Left", "Middle", "Right", "BottomLeft", "Bottom", "BottomRight"
}

-- Set every one to have a ceasefire but not be friends
function setup_forces()
    for _, source_force_name in ipairs(forces) do
        for _, target_force_name in ipairs(forces) do
            if not (source_force_name == target_force_name) then
                local source_force = game.forces[source_force_name]
                local target_force = game.forces[target_force_name]
                source_force.set_friend(target_force, false)
                source_force.set_cease_fire(target_force, true)
            end
        end 
    end
end

function on_player_created(event)
    
end