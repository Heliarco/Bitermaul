-- We got two jobs here
-- First we setup the force relationshipts to eachother
-- Second, we handle assigning joining players to forces as they join
table_helpers = require("libs/table_helpers")
math_helpers = require("libs/math_helpers")

local maul_player_forces = { -- The order here is also the order of player assignment
    "Bottom", "BottomLeft" , "BottomRight", "Middle","Left",  "Right" , "TopLeft", "Top", "TopRight"
}

local coin_name = "bitermaul-factory-coin"

-- Set every one to have a ceasefire but not be friends
local on_init = function()
    -- Set intra force ceasefire and friendship
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
    -- Set up force wallets
    global.force_coin_wallets = {}
    for _, force_name in ipairs(maul_player_forces) do
        global.force_coin_wallets[force_name] = 0
    end
    -- Pull in the coin item
    global.coin_item = game.item_prototypes[coin_name]
    if global.coin_item == nil then
        error("Could not get factory coin prototype")
    end
end


-- When you disconnect you are booted from the force
local on_player_left_game = function(event) 
    local player = game.players[event.player_index]
    local force = game.forces["player"]
    player.force = force
end

---@param event EventData.on_player_joined_game
local on_player_joined_game = function(event)
    -- First we find a valid force (with no players) to slot the player to (if none, we use "player")
    -- Then we move the player to the force

    ---@type LuaForce
    local candidate_force = game.forces["player"]
    for _, force_name in ipairs(maul_player_forces) do
        local force = game.forces[force_name]
        if  table_helpers.tablelength(force.players) == 0 then
            candidate_force = force
            break
        end
    end

    local player = game.players[event.player_index]
    player.force = candidate_force
    local spawn_position = candidate_force.get_spawn_position("nauvis")
    player.character.teleport(spawn_position)
end



-- Using entity.insert allows us to insert items in a players inventory and track how much makes it there
-- The idea is that we will guarentee that all coins given/ distributed will EVENTUALLY get into the pockets of players
-- We heavily assume only one player per force.

-- Here we blindly throw a set amount of coins at each force
---@param amount uint32
local give_coins_to_all_players = function(amount)
    for _, force_name in ipairs(maul_player_forces) do
        global.force_coin_wallets[force_name] = global.force_coin_wallets[force_name] + amount
    end
end

---@param amount uint32
local distribute_coins_between_players = function(amount)
    -- find forces with players, then distribute coins

    ---@type LuaForce[]
    local populated_forces = {}
    for _, force_name in ipairs(maul_player_forces) do
        local force = game.forces[force_name]
        if  table_helpers.tablelength(force.players) > 0 then
            table.insert(populated_forces, force)
        end
    end

    local force_count = table_helpers.tablelength(populated_forces)
    local count_dist = math_helpers.split_number_to_buckets(amount, force_count)
    for index, coins in ipairs(count_dist) do
        local force = populated_forces[index]
        global.force_coin_wallets[force.name] = global.force_coin_wallets[force.name] + amount
    end


end

local try_to_distribute_what_forces_are_owed = function()
    -- Find forces with players, try to get player character, if it is there (might not)
    -- Throw them some coins

    for _, force_name in ipairs(maul_player_forces) do
        local force = game.forces[force_name]
        if  table_helpers.tablelength(force.players) > 0 then
            local coins_owed = global.force_coin_wallets[force.name]
            if coins_owed > 0 then
                local player = force.players[1]    
                local transfered_coins = player.insert{name = coin_name, count = coins_owed}
                global.force_coin_wallets[force.name] = coins_owed - transfered_coins
            end
        end
    end
end

-- Attempts to refresh scouted terrain every 60th tick, so we can remove fog of war
-- Attempt to distribute owed cash
local on_60_tick = function()
    for _, force in pairs(game.forces) do
        force.chart_all()
    end 
    try_to_distribute_what_forces_are_owed()
end

force_management = {
    on_nth_tick = {
        [60] = on_60_tick
    },
    events = {
        [defines.events.on_player_joined_game] = on_player_joined_game,
        [defines.events.on_player_left_game] = on_player_left_game
    },
    on_init = on_init,
    give_coins_to_all_players = give_coins_to_all_players,
    distribute_coins_between_players = distribute_coins_between_players

}

return force_management