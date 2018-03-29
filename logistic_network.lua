require "util"  -- I don't know what it does
require "math"

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
  
function get_logistic_system_storage(player)
    return global.logistic_system_storage
end
  
function get_logistic_system_total_request(player)
    return global.logistic_system_total_request
end
  
function _get_logistic_system_storage(player, logistic_network)
    local contents = {}
  
    for _, storage in pairs(logistic_network.storages) do
      --log_to(player, storage.get_output_inventory().get_contents())
  
      for name, amount in pairs(storage.get_output_inventory().get_contents()) do 
        contents[name] = amount + (contents[name] or 0)
      end
    end
  
    for _, provider in pairs(logistic_network.providers) do
      local inventory = provider.get_output_inventory()
      if inventory ~= nil then
        for name, amount in pairs(inventory.get_contents()) do 
          contents[name] = amount + (contents[name] or 0)
        end
      elseif provider.type == "player" then
      else 
        log_to(player, "[ERROR] get_output_inventory() returns nil ("..provider.type..")")
      end
    end
  
    return contents
end
  
function _get_logistic_system_total_request(player, logistic_network)
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
  
    for name, _ in pairs(not_requesting_resources) do
      storage_contents[name] = nil
    end

    return storage_contents
end
  
function seed_position() 
    return {x=global.logistic_networks[1].x, y=global.logistic_networks[1].y} -- to copy
end
  
function seed_logistic_network(player)
    return player.surface.find_logistic_network_by_position(seed_position(), player.force)
end