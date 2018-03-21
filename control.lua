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
    --log_to(player, object_type.." is now being built")
    return
  end
  log_to(player, "Construct "..object_type)

  local surface = player.surface
  local initial_position = {x=0, y=0}

  local assembler_position = surface.find_non_colliding_position("assembling-machine-3", initial_position, 10, 5)
  if assembler_position == nil then
    log_to(player, "No place for assembler")
    return
  end

  local assembler_blueprint = global.blueprints[2]
  local assembler_result = assembler_blueprint.build_blueprint{surface=surface, force=player.force, position=assembler_position, force_build=true, direction=defines.direction.north}
  local assembler = assembler_result[1]

  if assembler == nil then
    log_to(player, "Can't build assembler")
    return
  end

  assembler.recipe = object_type
  global.now_building[object_type] = true

  local input_inserter_position = surface.find_non_colliding_position("fast-inserter", assembler_position, 10, 5)
  if input_inserter_position == nil then
    log_to(player, "No place for input inserter")
    return
  end

  local input_inserter_blueprint = global.blueprints[3]
  local input_inserter_result = input_inserter_blueprint.build_blueprint{surface=surface, force=player.force, position=input_inserter_position, force_build=true, direction=defines.direction.north}
  local input_inserter = input_inserter_result[1]

  if input_inserter == nil then
    --assembler がbuildされたタイミングで他のオブジェクトのcollisionを調べる

    log_to(player, "AAA-")
    log_to(player, initial_position)
    log_to(player, "AAA--")
    log_to(player, assembler_position)
    log_to(player, "AAA---")
    log_to(player, input_inserter_position)
    player.print(input_inserter_position)

    log_to(player, "AAA")
    log_to(player, input_inserter_blueprint.get_blueprint_entities())
    log_to(player, "AAAb")
    log_to(player, input_inserter_result)
    log_to(player, "AAAc")
    log_to(player, input_inserter)
    log_to(player, "Can't build input_inserter")
    return
  end

end

function log_to(player, message)
  if DEBUG then
    player.print(serpent.block(message))

  end
end
