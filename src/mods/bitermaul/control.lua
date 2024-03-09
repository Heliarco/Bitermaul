require("map_generation")


local mapgen_hooked = false

script.on_init(event)
  if not mapgen_hooked then
    script.on_event(defines.events.on_chunk_generated, map_generation_callback)
    mapgen_hooked = true
  end
end

script.on_load(event)
  if not mapgen_hooked then
    script.on_event(defines.events.on_chunk_generated, map_generation_callback)
    mapgen_hooked = true
  end
end



