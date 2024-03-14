require("map_generation")
require("force_management")

local function oninit(event)
  script.on_event(defines.events.on_chunk_generated, map_generation.on_chunk_generated)
  script.on_event(defines.events.on_player_joined_game, force_management.on_player_joined_game)
  force_management.setup_forces()
end


if script.level.level_name == "bitermaul" then
  script.on_init(oninit)
end
