require("map_generation")
require("force_management")
require("waves")

local function oninit(event)
  -- Map gen
  script.on_event(defines.events.on_chunk_generated, map_generation.on_chunk_generated)

  -- Player forces
  script.on_event(defines.events.on_player_joined_game, force_management.on_player_joined_game)
  force_management.oninit()

  -- Waves
  waves.oninit()
  script.on_event(defines.events.on_ai_command_completed, waves.on_ai_command_completed)
  -- script.on_event(defines.events.on_entity_destroyed)
  -- lets have some fun
  waves.spawn_wave(1)
end


if script.level.level_name == "bitermaul" then
  script.on_init(oninit)
end
