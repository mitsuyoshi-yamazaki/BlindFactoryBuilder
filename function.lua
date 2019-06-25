require "util"
require "math2d"

require "initializer"
require "utility"
require "logistic_network"

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

  return inventory
end

function build_missing_object(player)
  local alerts = player.get_alerts{}[0]
		local missing_construction_object_alerts 
		
		if alerts == nil then
				missing_construction_object_alerts = nil 
		else
				missing_construction_object_alerts = alerts[defines.alert_type.no_material_for_construction]
		end

		if alerts ~= nil then
		  for _, alert in pairs(alerts[defines.alert_type.entity_destroyed]) do
  		  construct_turret(player, alert.position)
				end
		end

		if missing_construction_object_alerts ~= nil then
		  if next(missing_construction_object_alerts) == nil then
  		  local roboport_position = next_roboport_position(player)
    		construct_roboport(player, roboport_position)
		    return
				end
		end

  -- queueに入っている方を優先
  for _, value in pairs(global.build_queue) do
    construct_from_blueprint(player, value.type, value.position)
  end

  local missing_roboports = 0
  local initial_position = seed_position()

		if missing_construction_object_alerts ~= nil then
		  for _, alert in pairs(missing_construction_object_alerts) do
  		  local missing_object_type = alert.target.ghost_name
    		--log_to(player, "Missing "..missing_object_type)

		    if missing_object_type == "roboport" then
  		    missing_roboports = missing_roboports + 1
    		end

		    global.logistic_system_total_request[missing_object_type] = (global.logistic_system_total_request[missing_object_type] or 0) - 1

  		  add_queue(missing_object_type, initial_position)

    		--construct_from_blueprint(player, missing_object_type, initial_position)
				end
		end

  if missing_roboports == 0 then
    local roboport_position = next_roboport_position(player)
    construct_roboport(player, roboport_position)
  end
end


--#### construct_from_blueprint ####--


function construct_from_blueprint(player, object_type, position, radius) 
  radius = radius or 1000 --default valueを使うとtableを渡すことになるのでこちらで行なっている

  if global.disable_new_construction and (global.has_assembler[object_type] ~= nil) then
    log_to(player, "New construction disabled")
    return
  end

  if raw_resources[object_type] or uncraftable_recipes[object_type] then
    log_to(player, "Cannot construct "..object_type)
    remove_from_queue(object_type, position)
    return
  end

  if is_building(object_type, position) then
    --log_to(player, is_building_key(object_type, position).." is now being built")
    return
  end

  local surface = player.surface

  local construct_position = surface.find_non_colliding_position("rocket-silo", position, radius, 2)  -- to find large area "rocket-silo" "oil-refinery"
  if construct_position == nil then
    log_to(player, "No place for construction")
    return
  end

  local blueprint = global.blueprints[2]
  local result = blueprint.build_blueprint{surface=surface, force=player.force, position=construct_position, force_build=true, direction=defines.direction.north}

  local entity_count = 0
  for _ in pairs(result) do entity_count = entity_count + 1 end

  if entity_count ~= NUMBER_OF_ENTITIES_IN_BLUEPRINT then
    --log_to(player, "Could not construct blueprint, conflicting to other ghosts ("..entity_count..")")

    for i, ghost in pairs(result) do
      ghost.destroy()
    end

    local next_position = {x=position.x + 10, y=position.y + 10}
    add_queue(object_type, next_position)  
    -- ここで呼ばなくても、is_buildingフラグが立っていないので、建設され次第collisionしない位置で建築されるが、それだとpositionが更新されない

    --log_to(player, "add_queue: "..object_type..", ("..tostring(construct_position.x)..", "..tostring(construct_position.y)..")")
    return
  end

  if next(result) == nil then
    log_to(player, "Could not construct blueprint")
    return
  end

  log_to(player, "Construct "..object_type)

  local entities = {}
  for _, entity in pairs(result) do 
    --log_to(player, entity.ghost_name)
    entities[entity.ghost_name] = entity
  end

  local assembler = entities["assembling-machine-3"]
		assembler.set_recipe(object_type)					

  local requester_chest = entities["logistic-chest-requester"]
  local logistic_network = logistic_network_covered(player, requester_chest)
  local stored_items = {}

  if logistic_network == nil then
    log_to(player, "No logistic network")
    return
  end

  local logistic_system_storage = get_logistic_system_storage(player)

  for i, ingredient in pairs(assembler.get_recipe().ingredients) do  -- assembler.recipe is LuaRecipe, object_type is String
    local ingredient_amount = math.min(ingredient.amount * 10, 100)
    
    requester_chest.set_request_slot({name=ingredient.name, count=ingredient_amount}, i)

    if (logistic_system_storage[ingredient.name] or 0) < ingredient.amount then
      --log_to(player, "lack of "..ingredient.name.."("..object_type..")")

      remove_now_building(ingredient.name, position)
      construct_from_blueprint(player, ingredient.name, {x=position.x + 3, y=position.y})
    else 
      --log_to(player, "enough amount of "..ingredient.name)
    end
  end

  add_now_building(object_type, position)
  remove_from_queue(object_type, position)
  global.has_assembler[object_type] = true
end


function construct_roboport(player, position)
  if DISABLE_ROBOPORT_AUTOCONSTRUCTION then
    return
  end

  local surface = player.surface
  local blueprint = global.blueprints[3]
  local result = blueprint.build_blueprint{surface=surface, force=player.force, position=position, force_build=true, direction=defines.direction.north}

  local area = {position, {position.x + 50, position.y + 50}}
  local entities = surface.find_entities(area)

  for _, entity in pairs(entities) do
    if (entity.type == "tree") or (entity.name == "stone-rock") then
      entity.order_deconstruction(player.force)
    end
  end
end

function construct_turret(player, position)
  local turret_position = convert_to_turret_position(player, position)

  if has_turret_on(player, turret_position) then
    return
  end

  local surface = player.surface
  local blueprint = global.blueprints[4]
  local result = blueprint.build_blueprint{surface=surface, force=player.force, position=turret_position, force_build=true, direction=defines.direction.north}
end

--#### check_missing_resources ####--


function check_missing_resources(player)
  local request = get_logistic_system_total_request(player)

  --log_to(player, "check_missing_resources")

  local least_resource_name = nil
  local least_resource_amount = 50

  local least_product_name = nil
  local least_product_amount = 50

  local missing_raw_resources = {}
  local missing_resource_unit = 4000

  for name, amount in pairs(request) do
    --log_to(player, name.." "..tostring(amount))
    if amount <= 50 then
      --log_to(player, "lack of "..name.." ("..tostring(amount)..")")
      
      if (global.has_assembler[name] == nil) and (intermediate_products[name] == nil) then
        local initial_position = seed_position()

								remove_now_building(name, initial_position)
        construct_from_blueprint(player, name, initial_position)
      end

      if (amount < least_resource_amount) and (intermediate_products[name] ~= nil) then
        least_resource_amount = amount
        least_resource_name = name
      end

      if (amount < least_product_amount) and (intermediate_products[name] == nil) then
        least_product_amount = amount
        least_product_name = name
      end
    end

    if raw_resources[name] and amount < missing_resource_unit then
      --log_to(player, "MISSING "..name)
      missing_raw_resources[name] = amount
    end
  end

  if least_resource_name ~= nil then
    --log_to(player, "lack of "..least_resource_name.." ("..tostring(least_resource_amount)..")")
    local initial_position = seed_position()

    remove_now_building(least_resource_name, initial_position)
    add_queue(least_resource_name, initial_position)
    --construct_from_blueprint(player, least_resource_name, initial_position)
  end

  if least_product_name ~= nil then
    --log_to(player, "lack of "..least_product_name.." ("..tostring(least_product_amount)..")")
    local initial_position = seed_position()

    remove_now_building(least_product_name, initial_position)
    add_queue(least_product_name, initial_position)
    --construct_from_blueprint(player, least_product_name, initial_position)
  end

  local logistic_network = seed_logistic_network(player)
  local fill_unit = 100

  for _, storage in pairs(logistic_network.storages) do
    if storage.name == "logistic-chest-storage" then
      for name, amount in pairs(missing_raw_resources) do
        --log_to(player, "Autofill "..name)

        local item = { name=name, count=fill_unit }
        local item_count = missing_resource_unit - amount
        local inventory = storage.get_output_inventory()

        while item_count > 0 do
          if inventory.can_insert(item) == false then
            break
          end

          inventory.insert(item)
          item_count = item_count - fill_unit
        end

        missing_raw_resources[name] = missing_resource_unit - item_count

        if item_count <= 0 then
          missing_raw_resources[name] = nil
        end
        break
      end
    end
  end
end


--## next_roboport_position ##--


function next_roboport_position(player) 
  if DISABLE_ROBOPORT_AUTOCONSTRUCTION then
    return {x=0, y=0}
  end

  if global.next_roboport["position"] == nil then
    global.next_roboport["position"] = seed_position(player)  -- これは「前回読み込まれた時の」位置
    global.next_roboport["direction_index"] = 0 -- これは「次回に読み込まれた時の」index
  end

  local rotation = {[0]={x=1, y=0}, [1]={x=0, y=1}, [2]={x=-1, y=0}, [3]={x=0, y=-1}}

  local current_index = global.next_roboport["direction_index"]
  local current_direction = rotation[current_index]
  local previous_position = global.next_roboport["position"]

  local roboport_interval = 50
  local x = previous_position.x + (current_direction.x * roboport_interval)
  local y = previous_position.y + (current_direction.y * roboport_interval)
  local position = {x=x, y=y}

  if can_roboport_built_on(player, position) then
  else 
    current_index = (current_index - 1 + 4) % 4
    current_direction = rotation[current_index]
    x = previous_position.x + (current_direction.x * roboport_interval)
    y = previous_position.y + (current_direction.y * roboport_interval)
    position = {x=x, y=y}
  
    -- 「ロボポートがなければ建てる」なので、立地的に建てられるかどうかは考慮しない
  end

  global.next_roboport["position"] = position
  global.next_roboport["direction_index"] = (current_index + 1) % 4
  return position
end

function can_roboport_built_on(player, position)
  return player.surface.find_entity("roboport", position) == nil
end
