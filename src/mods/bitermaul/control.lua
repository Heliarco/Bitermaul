if script.level.level_name == "bitermaul" then
  local handler          = require("event_handler")

  local map_generation   = require("control/map_generation")
  local force_management = require("control/force_management")
  local waves            = require("control/waves")
  local game_master      = require("control/game_master")

  handler.add_lib(waves)
  handler.add_lib(force_management)
  handler.add_lib(map_generation)
  handler.add_lib(game_master)

end