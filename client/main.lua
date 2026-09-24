local RESOURCE = GetCurrentResourceName()
local MAP_ID = '__map'
local KVP_KEY = 'rr_3dwaypoint:settings'
local L = Config.Locale
local GM = Config.GroundMarker

local waypoints = {} -- [id] = waypoint
local count = 0
local settings = {}
local nuiReady = false
local hiddenSent = true
local settingsOpen = false
local suppressedMap = nil -- blip coords we cleared ourselves; ignored until the player sets a new one

local abs, floor, min, max = math.abs, math.floor, math.min, math.max
local sin, cos, rad, deg = math.sin, math.cos, math.rad, math.deg
local atan, tan, log = math.atan, math.tan, math.log

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function clamp(v, lo, hi)
    return v < lo and lo or (v > hi and hi or v)
end

local function round(v, p)
    local m = 10 ^ p
    return floor(v * m + 0.5) / m
end

local function send(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function toast(title, sub, icon)
    if nuiReady then send('toast', { title = title, sub = sub, icon = icon }) end
end

local function toVec3(c)
    local t = type(c)
    if t == 'vector3' or t == 'vector4' then return vector3(c.x, c.y, c.z) end
    if t == 'vector2' then return vector3(c.x, c.y, 0.0) end
    if t == 'table' then
        local x, y, z = c.x or c[1], c.y or c[2], c.z or c[3] or 0.0
        if tonumber(x) and tonumber(y) then
            return vector3(x + 0.0, y + 0.0, (tonumber(z) or 0.0) + 0.0)
        end
    end
end

local function describe(pos)
    local s1 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
    local street = s1 ~= 0 and GetStreetNameFromHashKey(s1) or nil
    if street == '' then street = nil end

    local zone = GetLabelText(GetNameOfZone(pos.x, pos.y, pos.z))
    if zone == 'NULL' or zone == '' then zone = nil end

    if street and zone then return street .. ', ' .. zone end
    return street or zone or L.unknownLocation
end

local function estimateGround(x, y)
    if GetHeightmapTopZForPosition then
        local z = GetHeightmapTopZForPosition(x, y)
        if z and z > -200.0 then return z end
    end
    return GetEntityCoords(PlayerPedId()).z
end

---------------------------------------------------------------------------
-- Settings (per player, KVP)
---------------------------------------------------------------------------

local VALID_UNITS = { metric = true, imperial = true }

local function sanitize(key, value)
    local default = Config.Defaults[key]
    if default == nil or type(value) ~= type(default) then return nil end
    if key == 'units' then return VALID_UNITS[value] and value or nil end
    if key == 'scale' then return clamp(value, 0.7, 1.4) end
    if key == 'opacity' then return clamp(value, 0.3, 1.0) end
    return value
end

local function loadSettings()
    local s = {}
    for k, v in pairs(Config.Defaults) do s[k] = v end

    local raw = GetResourceKvpString(KVP_KEY)
    if raw then
        local ok, stored = pcall(json.decode, raw)
        if ok and type(stored) == 'table' then
            for k, v in pairs(stored) do
                local clean = sanitize(k, v)
                if clean ~= nil then s[k] = clean end
            end
        end
    end
    return s
end

local function saveSettings()
    SetResourceKvp(KVP_KEY, json.encode(settings))
    if nuiReady then send('settings', settings) end
end

settings = loadSettings()

---------------------------------------------------------------------------
-- Waypoints
---------------------------------------------------------------------------

local function metaOf(wp)
    return {
        id = wp.id,
        label = wp.label,
        sublabel = wp.sublabel,
        icon = wp.icon,
        kind = wp.id == MAP_ID and 'map' or 'custom',
    }
end

local function pushMeta(wp)
    if nuiReady then send('upsert', metaOf(wp)) end
end

local function probeGround(wp)
    local ok, z = GetGroundZFor_3dCoord(wp.coords.x, wp.coords.y, 1000.0, false)
    if not ok then return false end

    wp.coords = vector3(wp.coords.x, wp.coords.y, z)
    wp.needsGround = false
    if wp.autoSub then
        wp.sublabel = describe(wp.coords)
        pushMeta(wp)
    end
    return true
end

local function addWaypoint(id, data)
    if type(id) ~= 'string' and type(id) ~= 'number' then return false end
    id = tostring(id)
    data = type(data) == 'table' and data or {}

    local pos = toVec3(data.coords)
    if not pos then
        print(('[%s] waypoint "%s" has invalid coords'):format(RESOURCE, id))
        return false
    end

    local needsGround = data.findGround
    if needsGround == nil then needsGround = pos.z == 0.0 end
    if needsGround then pos = vector3(pos.x, pos.y, estimateGround(pos.x, pos.y)) end

    local wp = {
        id = id,
        coords = pos,
        needsGround = needsGround,
        label = tostring(data.label or L.waypoint),
        icon = data.icon or 'pin',
        arriveDistance = tonumber(data.arriveDistance) or Config.ArriveDistance,
        removeOnArrive = data.removeOnArrive, -- nil = follow the player's "Clear on arrival" setting
        groundMarker = data.groundMarker ~= false,
        heightOffset = tonumber(data.heightOffset) or Config.HeightOffset,
    }

    if data.sublabel then
        wp.sublabel = tostring(data.sublabel)
    else
        wp.autoSub = true
        wp.sublabel = describe(pos)
    end

    if not waypoints[id] then count = count + 1 end
    waypoints[id] = wp

    if needsGround then probeGround(wp) end
    pushMeta(wp)
    return true
end

local function removeWaypoint(id, reason)
    id = tostring(id)
    if not waypoints[id] then return false end

    waypoints[id] = nil
    count = count - 1
    if nuiReady then send('remove', { id = id, reason = reason or 'clear' }) end
    return true
end

local function clearAll()
    local ids = {}
    for id in pairs(waypoints) do ids[#ids + 1] = id end
    for i = 1, #ids do removeWaypoint(ids[i], 'clear') end
end

local function arrive(wp)
    TriggerEvent('rr-3dwaypoint:arrived', wp.id, wp.label)

    local remove = wp.removeOnArrive
    if remove == nil then remove = settings.autoClear end

    if remove then
        if wp.id == MAP_ID then
            suppressedMap = wp.rawCoords
            SetWaypointOff()
        end
        removeWaypoint(wp.id, 'arrive')
        toast(L.arrived, wp.label ~= L.waypoint and wp.label or wp.sublabel, 'check')
    else
        wp.arrived = true
    end
end

---------------------------------------------------------------------------
-- Projection
---------------------------------------------------------------------------

local function cameraBasis()
    local rot = GetFinalRenderedCamRot(2)
    local p, h = rad(rot.x), rad(rot.z)
    local cp = cos(p)

    local fx, fy, fz = -sin(h) * cp, cos(h) * cp, sin(p)
    local rx, ry, rz = cos(h), sin(h), 0.0
    local ux, uy, uz = ry * fz - rz * fy, rz * fx - rx * fz, rx * fy - ry * fx

    return GetFinalRenderedCamCoord(), fx, fy, fz, rx, ry, rz, ux, uy, uz
end

-- Returns screen x, y (0-1), whether it is on screen, and the edge arrow angle.
local function project(pos, cam, fx, fy, fz, rx, ry, rz, ux, uy, uz, tanV, aspect)
    local dx, dy, dz = pos.x - cam.x, pos.y - cam.y, pos.z - cam.z
    local z = dx * fx + dy * fy + dz * fz
    local x = dx * rx + dy * ry + dz * rz
    local y = dx * ux + dy * uy + dz * uz
    local m = Config.EdgeMargin

    if z > 0.05 then
        local sx = 0.5 + (x / (z * tanV * aspect)) * 0.5
        local sy = 0.5 - (y / (z * tanV)) * 0.5
        if sx >= m.x * 0.5 and sx <= 1.0 - m.x * 0.5 and sy >= m.y and sy <= 1.0 - m.y * 0.5 then
            return sx, sy, true, 0
        end
    end

    -- Off screen: direction in pixel space (height = 1). Things behind the camera sink to the bottom edge.
    local px, py = x, -y
    if z <= 0.05 then py = abs(py) + abs(z) * 0.35 end
    if abs(px) < 1e-4 and abs(py) < 1e-4 then py = 1.0 end

    local hw, hh = (0.5 - m.x) * aspect, 0.5 - m.y
    local t = min(abs(px) > 1e-6 and hw / abs(px) or math.huge, abs(py) > 1e-6 and hh / abs(py) or math.huge)

    return 0.5 + (px * t) / aspect, 0.5 + py * t, false, deg(atan(py, px))
end

-- Markers shrink gently with distance: 10 m -> 1.0, 100 m -> 0.85, 1 km -> 0.7.
local function scaleFor(dist)
    return round(clamp(1.15 - (log(max(dist, 1.0), 10)) * 0.15, 0.6, 1.05), 3)
end

local function drawGround(wp, dist, t)
    if wp.needsGround then return end

    local c = wp.coords
    local fade = 1.0 - clamp((dist - GM.distance * 0.6) / (GM.distance * 0.4), 0.0, 1.0)
    if fade <= 0.0 then return end

    if GM.beam then
        DrawMarker(1, c.x, c.y, c.z - 0.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.14, 0.14, 80.0,
            255, 255, 255, floor(40 * fade), false, false, 2, false, nil, nil, false)
    end

    if GM.ring then
        DrawMarker(25, c.x, c.y, c.z + 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.6, 1.6, 1.0,
            255, 255, 255, floor(150 * fade), false, false, 2, false, nil, nil, false)

        local p = (t % 1800) / 1800
        local s = 1.6 + p * 2.4
        DrawMarker(25, c.x, c.y, c.z + 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, s, s, 1.0,
            255, 255, 255, floor(120 * (1.0 - p) * fade), false, false, 2, false, nil, nil, false)
    end
end

local function shouldHide()
    return IsPauseMenuActive()
        or IsHudHidden()
        or IsPlayerSwitchInProgress()
        or IsScreenFadedOut()
        or IsCutsceneActive()
end

---------------------------------------------------------------------------
-- Threads
---------------------------------------------------------------------------

-- Render loop: projects every waypoint each frame and streams it to the NUI.
CreateThread(function()
    local speed = 0.0
    local fb = Config.FocusBox

    while true do
        local sleep = 300

        if nuiReady and settings.enabled and count > 0 and not shouldHide() then
            sleep = 0
            hiddenSent = false

            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            local pedPos = GetEntityCoords(ped)
            speed = speed + (GetEntitySpeed(veh ~= 0 and veh or ped) - speed) * 0.08

            local cam, fx, fy, fz, rx, ry, rz, ux, uy, uz = cameraBasis()
            local tanV = tan(rad(GetFinalRenderedCamFov()) * 0.5)
            local aspect = GetAspectRatio(false)
            local now = GetGameTimer()
            local list, n = {}, 0

            for id, wp in pairs(waypoints) do
                local dist = wp.needsGround and #(pedPos.xy - wp.coords.xy) or #(pedPos - wp.coords)

                if Config.MaxDistance <= 0 or dist <= Config.MaxDistance then
                    local anchor = vector3(wp.coords.x, wp.coords.y, wp.coords.z + wp.heightOffset)
                    local sx, sy, on, ang = project(anchor, cam, fx, fy, fz, rx, ry, rz, ux, uy, uz, tanV, aspect)

                    if on or settings.offscreen then
                        n = n + 1
                        list[n] = {
                            i = id,
                            x = round(sx, 4),
                            y = round(sy, 4),
                            o = on,
                            a = floor(ang + 0.5),
                            d = floor(dist + 0.5),
                            s = scaleFor(dist),
                            f = on and abs(sx - 0.5) < fb.x and abs(sy - 0.5) < fb.y,
                            e = speed > 1.5 and floor(dist / speed) or -1,
                        }
                    end

                    if settings.groundMarker and wp.groundMarker and dist < GM.distance then
                        drawGround(wp, dist, now)
                    end
                end
            end

            send('frame', { l = list, h = Config.DimWhenAiming and IsPlayerFreeAiming(PlayerId()) or false })
        elseif nuiReady and not hiddenSent then
            send('hide')
            hiddenSent = true
        end

        Wait(sleep)
    end
end)

-- Arrival checks + ground probing for waypoints whose collision wasn't loaded yet.
CreateThread(function()
    local tick = 0
    while true do
        Wait(250)
        tick = tick + 1

        if count > 0 then
            local pedPos = GetEntityCoords(PlayerPedId())
            local due = {}

            for _, wp in pairs(waypoints) do
                if wp.needsGround and tick % 4 == 0 then probeGround(wp) end

                local dist = #(pedPos.xy - wp.coords.xy)
                if not wp.needsGround then dist = #(pedPos - wp.coords) end

                if dist <= wp.arriveDistance then
                    if not wp.arrived then due[#due + 1] = wp end
                elseif wp.arrived and dist > wp.arriveDistance * 1.5 then
                    wp.arrived = false
                end
            end

            for i = 1, #due do arrive(due[i]) end
        end
    end
end)

-- Mirrors the GTA map waypoint.
CreateThread(function()
    if not Config.MapWaypoint then return end

    while true do
        Wait(400)
        local blip = GetFirstBlipInfoId(8)

        if blip ~= 0 and DoesBlipExist(blip) then
            local c = GetBlipInfoIdCoord(blip)
            local cur = waypoints[MAP_ID]

            if suppressedMap and #(c.xy - suppressedMap.xy) < 1.0 then
                -- Stale blip we cleared on arrival; wait for it to disappear or change.
            elseif not cur or not cur.rawCoords or #(c.xy - cur.rawCoords.xy) > 1.0 then
                suppressedMap = nil
                addWaypoint(MAP_ID, {
                    coords = vector3(c.x, c.y, 0.0),
                    label = L.waypoint,
                    icon = Config.MapWaypointIcon,
                    findGround = true,
                })
                waypoints[MAP_ID].rawCoords = c
                toast(L.waypointSet, waypoints[MAP_ID].sublabel, Config.MapWaypointIcon)
            end
        else
            suppressedMap = nil
            if removeWaypoint(MAP_ID, 'clear') then
                toast(L.waypointCleared, nil, 'close')
            end
        end
    end
end)

---------------------------------------------------------------------------
-- NUI
---------------------------------------------------------------------------

local function openSettings()
    if not nuiReady or settingsOpen then return end
    settingsOpen = true
    SetNuiFocus(true, true)
    send('settings:open')
end

local function closeSettings()
    if not settingsOpen then return end
    settingsOpen = false
    SetNuiFocus(false, false)
    send('settings:close')
end

RegisterNUICallback('ready', function(_, cb)
    nuiReady = true
    hiddenSent = false

    local list = {}
    for _, wp in pairs(waypoints) do list[#list + 1] = metaOf(wp) end

    send('init', { settings = settings, locale = L, waypoints = list })
    cb({ ok = true })
end)

RegisterNUICallback('saveSettings', function(data, cb)
    if type(data) == 'table' then
        for k, v in pairs(data) do
            local clean = sanitize(k, v)
            if clean ~= nil then settings[k] = clean end
        end
        SetResourceKvp(KVP_KEY, json.encode(settings))
    end
    cb(settings)
end)

RegisterNUICallback('resetSettings', function(_, cb)
    for k, v in pairs(Config.Defaults) do settings[k] = v end
    saveSettings()
    cb(settings)
end)

RegisterNUICallback('close', function(_, cb)
    closeSettings()
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(res)
    if res == RESOURCE and settingsOpen then SetNuiFocus(false, false) end
end)

---------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------

RegisterCommand(Config.Commands.toggle, function()
    settings.enabled = not settings.enabled
    saveSettings()
    toast(settings.enabled and L.enabled or L.disabled, nil, settings.enabled and 'eye' or 'eyeOff')
end, false)

RegisterCommand(Config.Commands.settings, openSettings, false)
RegisterKeyMapping(Config.Commands.settings, L.keybind, 'keyboard', Config.SettingsKey or '')

RegisterCommand(Config.Commands.clear, function()
    if waypoints[MAP_ID] then suppressedMap = waypoints[MAP_ID].rawCoords end
    SetWaypointOff()
    clearAll()
    toast(L.allCleared, nil, 'close')
end, false)

if Config.Debug then
    RegisterCommand('wptest', function()
        local ped = PlayerPedId()
        local p = GetEntityCoords(ped)
        local h = rad(GetEntityHeading(ped))
        local fx, fy = -sin(h), cos(h)

        addWaypoint('demo_front', { coords = vector3(p.x + fx * 60, p.y + fy * 60, 0.0), label = 'Delivery', icon = 'box', removeOnArrive = true })
        addWaypoint('demo_side', { coords = vector3(p.x + fy * 250, p.y - fx * 250, 0.0), label = 'Garage', icon = 'car' })
        addWaypoint('demo_back', { coords = vector3(p.x - fx * 1200, p.y - fy * 1200, 0.0), label = 'Home', icon = 'home' })
    end, false)
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------

exports('Add', addWaypoint)
exports('Remove', function(id) return removeWaypoint(id, 'clear') end)
exports('Clear', clearAll)
exports('Has', function(id) return waypoints[tostring(id)] ~= nil end)
exports('Get', function(id)
    local wp = waypoints[tostring(id)]
    if not wp then return nil end
    return { id = wp.id, coords = wp.coords, label = wp.label, sublabel = wp.sublabel, icon = wp.icon }
end)
exports('GetAll', function()
    local ids = {}
    for id in pairs(waypoints) do ids[#ids + 1] = id end
    return ids
end)
exports('SetEnabled', function(state)
    settings.enabled = state == true
    saveSettings()
end)
exports('IsEnabled', function() return settings.enabled end)
exports('OpenSettings', openSettings)

RegisterNetEvent('rr-3dwaypoint:add', addWaypoint)
RegisterNetEvent('rr-3dwaypoint:remove', function(id) removeWaypoint(id, 'clear') end)
RegisterNetEvent('rr-3dwaypoint:clear', clearAll)
