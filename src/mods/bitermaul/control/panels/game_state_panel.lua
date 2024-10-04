
-- Element types: https://lua-api.factorio.com/latest/concepts.html#GuiElementType





---@param event EventData.on_player_created
local on_player_created = function(event)
    local player = game.get_player(event.player_index)
    if player == nil then
        return
    end


    
    
    local screen_element = player.gui.screen
    local main_frame = screen_element.add{type="frame", name="game_state_panel-main_frame_title", caption={"bitermaul.game_state_panel_title"}}
    -- main_frame.style.size = {400,400} By commenting out it resizes to fit contents
    
    main_frame.location = {x = 10, y = 10}
    
    
    local content_frame = main_frame.add{type="frame", name="content_frame", direction="vertical", style="ugg_content_frame"}
    local controls_flow = content_frame.add{type="flow", name="controls_flow", direction="vertical", style="ugg_controls_flow"}

    
    controls_flow.add{type="label", name="game_state_panel-current_state_label", caption={"bitermaul.game_state_panel_current_state_label"}}
    controls_flow.add{type="label", name="game_state_panel-current_wave_label", caption={"bitermaul.game_state_panel_current_wave_label"}}
    
    controls_flow.add{type="button", name="game_state_panel-start_game", caption={"bitermaul.game_state_panel_start_game"}}
end




local game_state_panel = {
    events = {
        [defines.events.on_player_created] = on_player_created,
    },
}


return game_state_panel