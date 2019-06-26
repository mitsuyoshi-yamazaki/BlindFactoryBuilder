require "util"

require "utility"

--

-- TODO: move setup_factory() to on_configuration_changed event
script.on_event(defines.events.on_player_cheat_mode_enabled, function(event)
	for _, player in pairs(game.players) do
  setup_factory(player.force)
	end
end)

script.on_event(defines.events.on_tick, function(event)
		for _, player in pairs(game.players) do
    expand_factory(player)
  end
end)

-- Functions

function expand_factory(player)
  if OFF then 
    return 
  end

  if game.tick % 240 ~= 0 then
    return
		end

		if setup_player(player) ~= true then
			return
		end

end

function setup_player(player)
	return enable_cheat_mode(player)
end

function enable_cheat_mode(player)
	if player.cheat_mode == true then
		return true
	end

	player.force.research_all_technologies()
	player.cheat_mode = true
	player.print(player.name..": cheatmode is enabled")

	return false
end

function setup_factory(force)
	if global.factory == nil then
		global.factory = {}
	end
	if global.factory[force.name] ~= nil then 
		return
	end

	global.factory[force.name] = {}
	global.factory[force.name].recipes = force.recipes
end

function get_all_recipes(player)
	for _, recipe in pairs(player.force.recipes) do
		player.print(recipe.name.."::"..recipe.category)
		for _, ingredient in pairs(recipe.ingredients) do
			player.print("--"..ingredient.name.."("..ingredient.amount..")")
		end
	end
end
