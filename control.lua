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
    construct(player, missing_object_type)
  end
end

function construct(player, object_type)
  if global.now_building == nil then
    global.now_building = {}
  end 
  if global.now_building[object_type] ~= nil then
    return
  end

  local surface = player.surface
  local initial_position = {x=0, y=0}

  local assembler_position = surface.find_non_colliding_position("assembling-machine-3", initial_position, 10, 5)
  if assembler_position == nil then
    log_to(player, "No place for assembler")
    return
  end

  local assembler = player.surface.create_entity{name="entity-ghost", position=assembler_position, direction=defines.direction.north, force=player.force, recipe=object_type, inner_name="assembling-machine-3"}

  log_to(player, assembler)

  if assembler == nil then
    log_to(player, "Can't build assembler")
    return
  end

  global.now_building[object_type] = true
end

function log_to(player, message)
  if DEBUG then
    player.print(serpent.block(message))

  end
end
