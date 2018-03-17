require "util"  -- I don't know what it does

-- 

DEBUG = true

--

script.on_event(defines.events.on_tick, function(event)
  if game.tick % 30 == 0 then
    check_missing_construction_object_alert()
  end
end)

-- Functions

function check_missing_construction_object_alert()
  for _, player in pairs(game.players) do
    local missing_construction_object_alerts = player.get_alerts{}[0][3]

    logTo(player, missing_construction_object_alerts)

    if next(missing_construction_object_alerts) == nil then
      break
    end

    for _, alert in pairs(missing_construction_object_alerts) do
      local missing_object_type = alert.target.ghost_prototype.type
      logTo(player, "Missing "..missing_object_type)


    end
  end
end

function logTo(player, message)
  if DEBUG then
    player.print(serpent.block(message))

  end
end