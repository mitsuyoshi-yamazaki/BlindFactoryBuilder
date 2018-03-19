require "util"  -- I don't know what it does

-- 

DEBUG = true

--

script.on_event(defines.events.on_tick, function(event)
  if game.tick % 60 == 0 then
    for _, player in pairs(game.players) do
      blind_factory_builder(player)
    end
  end
end)

-- Functions

function blind_factory_builder(player)
  if global.blueprints ~= nil then
    return
  end

  local blueprints = get_init_blueprints(player)
  if blueprints == nil then 
    return
  end

  global.blueprints = blueprints[2]

  log_to(player, "blueprints set")

  global.blueprints.build_blueprint{surface=player.surface, force=player.force, position={x=0, y=0}}
  --check_missing_construction_object_alert(player)
end

function get_init_blueprints(player)
  local selected_entity = player.selected
  if selected_entity == nil then
    return
  end
  if selected_entity.type ~= "container" then
    return
  end

  local inventory = selected_entity.get_inventory(defines.inventory.chest)
  if inventory[1].valid_for_read == false then 
    return
  end
  if inventory[1].label ~= "__init__" then
    return
  end

  log_to(player, "blueprints set")
  return inventory
end

function check_missing_construction_object_alert(player)
  local missing_construction_object_alerts = player.get_alerts{}[0][3]

  if next(missing_construction_object_alerts) == nil then
    return
  end

  for _, alert in pairs(missing_construction_object_alerts) do
    local missing_object_type = alert.target.ghost_prototype.type
    --log_to(player, "Missing "..missing_object_type)

    construct(player, missing_object_type)
  end
end

function construct(player, object_type)

end

function log_to(player, message)
  if DEBUG then
    player.print(serpent.block(message))

  end
end