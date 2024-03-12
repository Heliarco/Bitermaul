local tile_name_unbuildable = "water-shallow"
local tile_name_outside = "out-of-map" -- water ?
local tile_name_buildable = "landfill"

local map_shape = {}

---@return nil
---@param x int
---@param y int
---@param tile string
local function set_tile(x, y, tile)
    if map_shape[x] == nil then
        map_shape[x] = {}
    end
    map_shape[x][y] = tile
end

---@return nil
---@param x int
---@param y int
---@param width uint
---@param height uint
---@param tile string
local function set_square(x,y,width,height, tile)
    for i_x=x, x+width do
        for i_y=y, y+height do
            set_tile(i_x,i_y,tile)
        end
    end
end






local function map_generation_callback(event)
    mapgen_hooked = true
    
    -- Lets unpack event data
    ---@type BoundingBox
    local area = event.area
    ---@type ChunkPosition
    local position = event.position
    ---@type LuaSurface
    local surface = event.surface
    ---@type defines.events
    local name = event.name
    ---@type uint
    local tick = event.tick

    
    -- We only want to deal with nauvis.
    if surface.name ~= "nauvis" then
        return
    end
    local x1 = event.area.left_top.x
    local y1 = event.area.left_top.y
    local x2 = event.area.right_bottom.x
    local y2 = event.area.right_bottom.y
    local tiles = {}
    for x = x1, x2 do
        for y = y1, y2 do
            if map_shape[x] ~= nil and map_shape[x][y] ~= nil then
                table.insert(tiles, {name = map_shape[x][y], position = {x, y}})
            else
                table.insert(tiles, {name = tile_name_outside, position = {x, y}})
            end
        end
    end

    surface.set_tiles(tiles)
end

function register_chunk_callback(pattern)
    assert(global.enabled)
    assert(pattern.output == 'tile')
    local get = pattern.get
    local get_chunk = pattern.get_chunk
    local vectorize = (get_chunk ~= nil)
    local callback
    local insert = table.insert
    local force_initial_water = global.settings['force-initial-water']

    -- Check for 'nauvis' per EldVarg, for Factorissimo compatibility

    if vectorize then
        callback = function(event)
            local surface = event.surface
            if surface.name ~= "nauvis" then
                return
            end
            local x1 = event.area.left_top.x
            local y1 = event.area.left_top.y
            local x2 = event.area.right_bottom.x
            local y2 = event.area.right_bottom.y

            local tiles

            if near_origin(x1, y1) then
                tiles = {}
                for x = x1, x2 do
                    for y = y1, y2 do
                        if force_initial_water and ((x - 7) * (x - 7) + y * y < 10) then
                            insert(tiles, {name = 'water', position = {x, y}})
                        elseif (x * x + y * y > 5) then
                            local new = get(x, y)
                            if new ~= nil then
                                insert(tiles, {name = new, position = {x, y}})
                            end
                        end
                    end
                end
            else
                tiles = get_chunk(x1, y1, x2, y2)
            end

            surface.set_tiles(tiles)
        end
    else
        callback = function(event)
            local surface = event.surface
            if surface.name ~= "nauvis" then
                return
            end
            local x1 = event.area.left_top.x
            local y1 = event.area.left_top.y
            local x2 = event.area.right_bottom.x
            local y2 = event.area.right_bottom.y

            local tiles = {}

            if near_origin(x1, y1) then
                for x = x1, x2 do
                    for y = y1, y2 do
                        if force_initial_water and ((x - 7) * (x - 7) + y * y < 10) then
                            insert(tiles, {name = 'water', position = {x, y}})
                        elseif (x * x + y * y > 5) then
                            local new = get(x, y)
                            if new ~= nil then
                                insert(tiles, {name = new, position = {x, y}})
                            end
                        end
                    end
                end
            else
                for x = x1, x2 do
                    for y = y1, y2 do
                        local new = get(x, y)
                        if new ~= nil then
                            insert(tiles, {name = new, position = {x, y}})
                        end
                    end
                end
            end

            surface.set_tiles(tiles)
        end
    end

    script.on_event(defines.events.on_chunk_generated, callback)
end


local mapgen_hooked = false
function hook_map_gen()
    if mapgen_hooked then
        return
    end
    script.on_event(defines.events.on_chunk_generated, map_generation_callback)
end

--- Now we build a level

set_square(-3, -3, 6, 6, tile_name_buildable)