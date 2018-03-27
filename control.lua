require "util"  -- I don't know what it does
require "math"

-- 

OFF = false
DEBUG = true
RESET_ALL = false
RESET_BLUEPRINTS = false
RESET_LOGISTIC_NETWORK = false
RESET = false

CONSTRUCT_ROBOTS = false

NUMBER_OF_ENTITIES_IN_BLUEPRINT = 6

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

  if game.tick % 60 ~= 0 then
    return
  end

  initialize(player)

  --global.blueprints.build_blueprint{surface=player.surface, force=player.force, position={x=0, y=0}}
  
  build_missing_object(player)

  if CONSTRUCT_ROBOTS then
    CONSTRUCT_ROBOTS = false
    construct_from_blueprint(player, "construction-robot", {x=0, y=0})
    construct_from_blueprint(player, "logistic-robot", {x=0, y=0})
    construct_from_blueprint(player, "repair-pack", {x=0, y=0})
  end

  --if game.tick % 3600 == 0 then
  if game.tick % 600 == 0 then
    check_missing_resources(player)
  end

  --test(player)
end

function initialize(player) 
  if DEBUG then
    if RESET_ALL then
      RESET_ALL = false
      log_to(player, "RESET ALL")
      global.blueprints = nil
      global.now_building = {}
    end
    
    if RESET_BLUEPRINTS then
      RESET_BLUEPRINTS = false
      log_to(player, "RESET BLUEPRINTs")
      global.blueprints = nil
    end
    
    if RESET_LOGISTIC_NETWORK then
      RESET_LOGISTIC_NETWORK = false
      log_to(player, "RESET LOGISTIC NETWORK")
      global.logistic_networks = nil
    end

    if RESET then
      RESET = false
      log_to(player, "RESET VARIABLES")
      global.now_building = nil
      global.build_queue = nil
    end
  end
    
  if global.blueprints == nil then
    local blueprints = get_init_blueprints(player)
    if blueprints == nil then 
      log_to(player, "No blueprint set")
    else 
      global.blueprints = blueprints
    end      
  end

  if global.now_building == nil then
    global.now_building = {}
  end

  if global.build_queue == nil then 
    global.build_queue = {}
  end

  if global.logistic_networks == nil then
    local position = selected_logistic_network_position(player)
    if position == nil then
      log_to(player, "No logistic network set")
    else
      log_to(player, "Logistic network set")
      global.logistic_networks = {}
      global.logistic_networks[1] = position  
    end
  end
end

function selected_logistic_network_position(player)
  if player.selected == nil then
    return nil
  end

  local logistic_network = player.selected.logistic_network
  if logistic_network == nil then
    --log_to(player, "no logistic_network")
    return nil
  end

  return player.selected.position
end

function selected_logistic_network(player)
  if player.selected == nil then
    return nil
  end

  local logistic_network = player.selected.logistic_network
  if logistic_network == nil then
    --log_to(player, "no logistic_network")
    return nil
  end

  return logistic_network
end

function logistic_network_covered(player, entity)
  if entity == nil then
    return nil
  end

  local surface = entity.surface
  if surface == nil then
    return nil
  end

  return surface.find_logistic_network_by_position(entity.position, entity.force)
end

function test(player)
  local logistic_network = logistic_network_covered(player, player.selected)

  if logistic_network == nil then
    log_to(player, "no logistic_network")
    return
  end

  local storages = logistic_network.storages
  log_to(player, storages)

  local storage_points = logistic_network.storage_points
  --log_to(player, storage_points)

  local contents = {}

  for _, storage in pairs(storages) do
    --log_to(player, storage.get_output_inventory().get_contents())

    for name, amount in pairs(storage.get_output_inventory().get_contents()) do 
      contents[name] = amount + (contents[name] or 0)
    end
  end

  log_to(player, "contents: ")
  log_to(player, contents)
  
end

function get_logistic_system_storage(player, logistic_network)
  local contents = {}

  for _, storage in pairs(logistic_network.storages) do
    --log_to(player, storage.get_output_inventory().get_contents())

    for name, amount in pairs(storage.get_output_inventory().get_contents()) do 
      contents[name] = amount + (contents[name] or 0)
    end
  end

  for _, provider in pairs(logistic_network.providers) do
    for name, amount in pairs(provider.get_output_inventory().get_contents()) do 
      contents[name] = amount + (contents[name] or 0)
    end
  end

  return contents
end

function get_logistic_system_total_request(player, logistic_network)
  local storage_contents = get_logistic_system_storage(player, logistic_network)

  for _, requester in pairs(logistic_network.requesters) do
    for i, _ in pairs({[1]=1, [2]=2, [3]=3, [4]=4, [5]=5}) do -- ingredientsは5つまで
      local slot = requester.get_request_slot(i)
      if slot == nil then 
        break 
      end
      storage_contents[slot.name] = (storage_contents[slot.name] or 0) - slot.count
    end
  end

  return storage_contents
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

  -- queueに入っている方を優先
  for _, value in pairs(global.build_queue) do
    construct_from_blueprint(player, value.type, value.position)
  end

  for _, alert in pairs(missing_construction_object_alerts) do
    local missing_object_type = alert.target.ghost_name

    construct_from_blueprint(player, missing_object_type, alert.position)
  end
end

function log_to(player, message)
  if DEBUG then
    player.print(serpent.block(message))

  end
end

function construct_from_blueprint(player, object_type, position) 
  if is_building(object_type, position) then
    --log_to(player, is_building_key(object_type, position).." is now being built")
    return
  end
  log_to(player, "Construct "..object_type)

  local surface = player.surface
  local initial_position = global.logistic_networks[1]

  local construct_position = surface.find_non_colliding_position("oil-refinery", initial_position, 100, 2)  -- to find large area
  if construct_position == nil then
    log_to(player, "No place for construction")
    return
  end

  -- surfaceからlogistic_networkを求める
  -- http://lua-api.factorio.com/0.15.40/LuaLogisticNetwork.html#LuaLogisticNetwork.find_cell_closest_to

  local blueprint = global.blueprints[2]
  local result = blueprint.build_blueprint{surface=surface, force=player.force, position=construct_position, force_build=true, direction=defines.direction.north}

  local entity_count = 0
  for _ in pairs(result) do entity_count = entity_count + 1 end

  if entity_count ~= NUMBER_OF_ENTITIES_IN_BLUEPRINT then
    --log_to(player, "Could not construct blueprint, conflicting to other ghosts ("..entity_count..")")

    for i, ghost in pairs(result) do
      ghost.destroy()
    end

    local next_position = {x=position.x + 5, y=position.y}
    add_queue(object_type, next_position)  
    -- ここで呼ばなくても、is_buildingフラグが立っていないので、建設され次第collisionしない位置で建築されるが、それだとpositionが更新されない
    return
  end

  if next(result) == nil then
    log_to(player, "Could not construct blueprint")
    return
  end

  local entities = {}
  for _, entity in pairs(result) do 
    --log_to(player, entity.ghost_name)
    entities[entity.ghost_name] = entity
  end

  --log_to(player, result)

  local assembler = entities["assembling-machine-3"]
  assembler.recipe = object_type

  local requester_chest = entities["logistic-chest-requester"]
  local logistic_network = logistic_network_covered(player, requester_chest)
  local stored_items = {}

  if logistic_network == nil then
    log_to(player, "No logistic network")
    return
  end

  local logistic_system_storage = get_logistic_system_storage(player, logistic_network)
  --log_to(player, logistic_system_storage)

  for i, ingredient in pairs(assembler.recipe.ingredients) do  -- assembler.recipe is LuaRecipe, not String
    local ingredient_amount = math.min(ingredient.amount * 10, 100)
    
    requester_chest.set_request_slot({name=ingredient.name, count=ingredient_amount}, i)

    if (logistic_system_storage[ingredient.name] or 0) < ingredient.amount then
      log_to(player, "lack of "..ingredient.name)
      add_queue(ingredient.name, {x=position.x + 3, y=position.y})
    else 
      log_to(player, "enough amount of "..ingredient.name)
    end
  end

  --local provider_chest = entities["logistic-chest-passive-provider"]
  --log_to(player, provider_chest.get_inventory(defines.inventory.burnt_result))

  add_now_building(object_type, position)
  remove_from_queue(object_type, position)
end

--
function check_missing_resources(player)
  local logistic_network = seed_logistic_network(player)
  local request = get_logistic_system_total_request(player, logistic_network)

  log_to(player, "check_missing_resources")
  --log_to(player, request)

  local least_resource_name = nil
  local least_resource_amount = 0

  for name, amount in pairs(request) do
    if amount <= 1 then
      --log_to(player, "lack of "..name.." ("..tostring(amount)..")")
      
      if amount < least_resource_amount then
        least_resource_amount = amount
        least_resource_name = name
      end
    end
  end

  if least_resource_name ~= nil then
    log_to(player, "lack of "..least_resource_name.." ("..tostring(least_resource_amount)..")")

    remove_now_building(least_resource_name, {x=0, y=0})
    construct_from_blueprint(player, least_resource_name, {x=0, y=0})
  end

  for _, storage in pairs(logistic_network.storages) do
    storageがstorageか調べる
    storageなら足りない資源を補充

    for name, amount in pairs(storage.get_output_inventory().get_contents()) do 
      contents[name] = amount + (contents[name] or 0)
    end
  end
end

-- Utility

function add_now_building(object_type, position)
  local key = is_building_key(object_type, position)
  global.now_building[key] = true
  -- No way to remove any key from now_building
end

function remove_now_building(object_type, position) -- keyにpositionが使われると動かなくなる
  local key = is_building_key(object_type, position)
  global.now_building[key] = nil
end

function is_building(object_type, position)
  local key = is_building_key(object_type, position)
  return global.now_building[key] ~= nil
end

function is_building_key(object_type, position)
  --return object_type.." {x="..position.x..", y="..position.y.."}" -- Since position could be either Position object or map
  return object_type
end

function add_queue(object_type, position)
  local key = is_building_key(object_type, position)
  global.build_queue[key] = { type=object_type, position=position }
end

function remove_from_queue(object_type, position)
  local key = is_building_key(object_type, position)
  global.build_queue[key] = nil
end

---

function seed_logistic_network(player)
  local seed_position = global.logistic_networks[1]
  return player.surface.find_logistic_network_by_position(seed_position, player.force)
end