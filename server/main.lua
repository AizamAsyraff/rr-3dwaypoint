-- Server-side helpers. Pass -1 as the target to affect every player.

exports('AddForPlayer', function(target, id, data)
    TriggerClientEvent('rr-3dwaypoint:add', target, id, data)
end)

exports('RemoveForPlayer', function(target, id)
    TriggerClientEvent('rr-3dwaypoint:remove', target, id)
end)

exports('ClearForPlayer', function(target)
    TriggerClientEvent('rr-3dwaypoint:clear', target)
end)
