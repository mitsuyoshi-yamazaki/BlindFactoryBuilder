require "util"  -- I don't know what it does
require "math"

-- Utility

function add_now_building(object_type, position)
    local key = is_building_key(object_type, position)
    global.now_building[key] = game.tick
    -- No way to remove any key from now_building
end
  
function remove_now_building(object_type, position) -- keyにpositionが使われると動かなくなる
    local key = is_building_key(object_type, position)
  
    if global.now_building[key] == nil then
      return
    end
  
    global.now_building[key] = nil
end
  
function is_building(object_type, position)
    local key = is_building_key(object_type, position)
    local build_started_at = global.now_building[key]

    if build_started_at == nil then 
        return false
    end

    if true then
        return true --FixMe:
    end

    local threshold = 60 * 15

    if (game.tick - build_started_at) > threshold then
        return false
    end

    return true
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
  
function log_to(player, message)
    if DEBUG then
      player.print(serpent.block(message))
  
    end
end

function turret_key(player, position)
    return "("..tostring(position.x)..", "..tostring(position.y)..")"
end
  
function has_turret_on(player, position)
    local key = turret_key(player, position)
    return global.turret_locations[key] ~= nil
end

function convert_to_turret_position(player, position)
    local initial_position = seed_position()

    local x = (math.floor(position.x / 25) * 25) + 12 + (initial_position.x % 25)
    local y = (math.floor(position.y / 25) * 25) + 13 + (initial_position.y % 25)
    return {x=x, y=y}
end