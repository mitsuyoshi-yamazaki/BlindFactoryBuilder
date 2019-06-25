require "util"

require "function"

--

script.on_event(defines.events.on_tick, function(event)
		for _, player in pairs(game.players) do
    blind_factory_builder(player)
  end
end)

-- Functions

function blind_factory_builder(player)
  if OFF then 
    return 
  end

  if game.tick % 240 ~= 0 then
    return
		end

  if initialize(player) ~= true then
    return
  end

  if INITIALIZATION_ONLY then
    return
  end
  
  local logistic_network = seed_logistic_network(player)
  global.logistic_system_storage = _get_logistic_system_storage(player, logistic_network)
  global.logistic_system_total_request = _get_logistic_system_total_request(player, logistic_network)

  build_missing_object(player)

  if game.tick % 600 == 0 then
    check_missing_resources(player)
  end
end

