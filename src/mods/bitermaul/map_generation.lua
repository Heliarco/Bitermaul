local tile_name_outside = "out-of-map"

-- In case we SOMEHOW manage to generate more chunks, we force write them as "out-of-map" aka black void



local function map_generation_callback(event)
    ---@type LuaSurface
    local surface = event.surface
    
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
            table.insert(tiles, {name = tile_name_outside, position = {x, y}})
        end
    end

    surface.set_tiles(tiles)
end

local mapgen_hooked = false
function hook_map_gen()
    mapgen_hooked = true
    if mapgen_hooked then
        return
    end
    script.on_event(defines.events.on_chunk_generated, map_generation_callback)
end