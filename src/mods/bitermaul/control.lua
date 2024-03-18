if script.level.level_name == "bitermaul" then
  local map_generation   = require("map_generation")
  local force_management = require("force_management")
  local waves            = require("waves")
  local game_master      = require("game_master")
  local handler          = require("event_handler")

  handler.add_lib(waves)
  handler.add_lib(force_management)
  handler.add_lib(map_generation)
  handler.add_lib(game_master)

end