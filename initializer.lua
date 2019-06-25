require "util"  -- I don't know what it does
require "logistic_network"

OFF = false
INITIALIZATION_ONLY = false
DISABLE_ROBOPORT_AUTOCONSTRUCTION = true
DISABLE_NEW_CONSTRUCTION = false

DEBUG = true

RESET_ALL = true
RESET_BLUEPRINTS = false
RESET_LOGISTIC_NETWORK = false
RESET = false

NUMBER_OF_ENTITIES_IN_BLUEPRINT = 6

-- 本Modで作成できない資源
raw_resources = { 
  ["iron-plate"]=true, 
  ["copper-plate"]=true,
  ["steel-plate"]=true,
  ["plastic-bar"]=true, 
  ["battery"]=true,
  ["concrete"]=true,
  ["stone-brick"]=true,
  ["electric-engine-unit"]=true,
  ["processing-unit"]=true,
  ["raw-wood"]=true,
  ["express-transport-belt"]=true,
  ["express-underground-belt"]=true,
  ["uranium-fuel-cell"]=true,
} 

intermediate_products = {
  ["copper-cable"]=true,
  ["iron-stick"]=true,
  ["iron-gear-wheel"]=true,
  ["electronic-circuit"]=true,
  ["advanced-circuit"]=true,
  ["engine-unit"]=true,
}

uncraftable_recipes = {
  ["straight-rail"]=true,
  ["stone"]=true,
}

not_requesting_resources = {
  ["raw-wood"]=true,
  ["stone"]=true,
}

--

function initialize(player) 
    local initialization_succeeded = true

    if DEBUG then      
      if RESET_BLUEPRINTS or RESET_ALL then
        RESET_BLUEPRINTS = false
        log_to(player, "RESET BLUEPRINTs")
        global.blueprints = nil
      end
      
      if RESET_LOGISTIC_NETWORK or RESET_ALL then
        RESET_LOGISTIC_NETWORK = false
        log_to(player, "RESET LOGISTIC NETWORK")
        global.logistic_networks = nil
      end
  
      if RESET or RESET_ALL then
        RESET = false
        log_to(player, "RESET VARIABLES")
        global.now_building = nil
        global.build_queue = nil
        global.has_assembler = nil
        global.next_roboport = nil
        global.turret_locations = nil
        global.disable_new_construction = nil
      end

      if RESET_ALL then --ここで RESET_ALL = false しているので最後に呼ぶ必要がある
        RESET_ALL = false
        log_to(player, "RESET ALL")
        global.blueprints = nil
        global.now_building = {}
      end
    end
      
    --global.now_building = nil

    if global.blueprints == nil then
      local blueprints = get_init_blueprints(player)
      if blueprints == nil then 
        log_to(player, "No blueprint set")
        initialization_succeeded = false
      else 
        log_to(player, "blueprint set")
        global.blueprints = blueprints
      end      
    end
  
    if global.now_building == nil then
      global.now_building = {}
    end
  
    if global.build_queue == nil then 
      global.build_queue = {}
    end
  
    if global.has_assembler == nil then
      global.has_assembler = {}
    end

    if global.next_roboport == nil then
      global.next_roboport = {}
    end

    if global.turret_locations == nil then
      global.turret_locations = {}
    end
  
    if global.logistic_networks == nil then
      local position = selected_logistic_network_position(player)
      if position == nil then
        log_to(player, "No logistic network set")
        initialization_succeeded = false
      else
        log_to(player, "Logistic network set")
        global.logistic_networks = {}
        global.logistic_networks[1] = position  
      end
    end

    if DISABLE_NEW_CONSTRUCTION then
        global.disable_new_construction = true
    end

    return initialization_succeeded
end
  
