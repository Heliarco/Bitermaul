--- Helpers to handle coins being given out to players
--- Provides a method to distribute coins
--- distribute_coins(amount)
--- Handles biter kills and autonomously distributes coins there

local maul_player_forces = { -- The order here is also the order of player assignment
    "Bottom", "BottomLeft" , "BottomRight", "Middle","Left",  "Right" , "TopLeft", "Top", "TopRight"
}
local table_helpers = require("libs/table_helpers")

local coin_name = "bitermaul-factory-coin"

local math_helpers = require("libs/math_helpers")

local on_init = function()
    -- Pull in the coin item
    global.money_distributer.coin_item = game.item_prototypes[coin_name]
    if global.money_distributer.coin_item == nil then
        error("Could not get factory coin prototype")
    end
end



-- Using entity.insert allows us to insert items in a players inventory and track how much makes it there
-- The idea is that we will guarentee that all coins given/ distributed will EVENTUALLY get into the pockets of players
-- We heavily assume only one player per force.


-- Give money to force
---@param amount uint32
---@param force_name string
local distribute_coins_to_force = function(amount, force_name)
    local force = game.forces[force_name]
    if table_helpers.tablelength(force.players) > 0 then
        local player = force.players[1]
        player.insert{name = coin_name, count = amount}    
    end
end

-- Here we blindly throw a set amount of coins at each force
---@param amount uint32
local distribute_coins = function(amount)
    for _, force_name in ipairs(maul_player_forces) do
        distribute_coins_to_force(amount, force_name)
    end
end


force_management = {
    on_init = on_init,
    distribute_coins = distribute_coins,
    distribute_coins_to_force = distribute_coins_to_force
}

return force_management