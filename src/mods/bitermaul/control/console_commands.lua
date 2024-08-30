local on_init = function()
    commands.add_command("print_tick", nil, function(command)
        if command.player_index ~= nil and command.parameter == "me" then
            game.get_player(command.player_index).print(command.tick)
        else
            game.print(command.tick)
        end
        end)
end

local console_commands = {
    on_init = on_init
}
return console_commands