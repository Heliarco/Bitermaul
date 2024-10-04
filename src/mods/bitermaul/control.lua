if script.level.level_name == "bitermaul" then
  local handler             = require("event_handler")


  --- Control scripts
  local globals             = require("control/globals") -- Just for initialization
  local map_generation      = require("control/map_generation")
  local force_management    = require("control/force_management")
  local waves               = require("control/waves")
  local game_master         = require("control/game_master")
  local console_commands    = require("control/console_commands")
  local money_distributer   = require("control/services/money_distributer")
  local game_state_panel    = require("control/panels/game_state_panel")

  handler.add_lib(globals)
  handler.add_lib(waves)
  handler.add_lib(force_management)
  handler.add_lib(map_generation)
  handler.add_lib(game_master)
  handler.add_lib(console_commands)
  handler.add_lib(money_distributer)
  handler.add_lib(game_state_panel)
end