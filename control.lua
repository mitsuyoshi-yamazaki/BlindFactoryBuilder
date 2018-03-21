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
  if global.blueprints == nil then
    local blueprints = get_init_blueprints(player)
    if blueprints == nil then 
      return
    end      
    global.blueprints = blueprints
  end

  --global.blueprints.build_blueprint{surface=player.surface, force=player.force, position={x=0, y=0}}
  
  build_missing_object(player)
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

function build_missing_object(player)
  local missing_construction_object_alerts = player.get_alerts{}[0][3]

  if next(missing_construction_object_alerts) == nil then
    return
  end

  for _, alert in pairs(missing_construction_object_alerts) do
    local missing_object_type = alert.target.ghost_prototype.type
    log_to(player, "Missing "..missing_object_type)

    construct(player, missing_object_type)
  end
end

function construct(player, object_type)
  local assembler_blueprint = global.blueprints[2]
  local surface = player.surface
  local initial_position = {x=0, y=0}
  local position = surface.find_non_colliding_position("assembling-machine-3", initial_position, 10, 5)

  log_to(player, position)

  if position == nil then
    log_to(player, "Can't find non colliding position")
    return
  end

  local direction = defines.direction.north
  local built = assembler_blueprint.build_blueprint{surface=surface, force=player.force, position=position, force_build=true, direction=direction}
  local assembler = built[1]

  if assembler == nil then
    log_to(player, "Can't build")
    return
  end

  assembler.recipe = object_type
end

function log_to(player, message)
  if DEBUG then
    player.print(serpent.block(message))

  end
end
