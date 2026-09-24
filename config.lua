Config = {}

-- Enables /wptest (spawns three demo waypoints around you).
Config.Debug = false

Config.Commands = {
    toggle   = 'wp',         -- enable / disable the 3D waypoints
    settings = 'wpsettings', -- open the settings panel
    clear    = 'wpclear',    -- remove the map waypoint and every custom waypoint
}

-- Default key for the settings panel ('' = unbound). Players can rebind it in
-- Settings > Key Bindings > FiveM.
Config.SettingsKey = ''

-- Mirror the regular GTA map waypoint as a 3D marker.
Config.MapWaypoint = true
Config.MapWaypointIcon = 'flag'

Config.HeightOffset = 1.0     -- metres above the ground where the marker is anchored
Config.ArriveDistance = 20.0  -- metres; default for every waypoint
Config.MaxDistance = 0        -- hide waypoints further than this (0 = unlimited)
Config.DimWhenAiming = true   -- fade the HUD while free-aiming

-- Screen-edge padding for off-screen indicators (fraction of the screen).
Config.EdgeMargin = { x = 0.035, y = 0.07 }

-- A marker inside this box around the screen centre expands to show details.
Config.FocusBox = { x = 0.09, y = 0.13 }

-- In-world light beam + pulsing ground ring.
Config.GroundMarker = {
    distance = 300.0,
    beam = true,
    ring = true,
}

-- Per-player defaults (players change these in the settings panel; saved with KVP).
Config.Defaults = {
    enabled      = true,
    offscreen    = true,
    showStreet   = true,
    showEta      = true,
    groundMarker = true,
    autoClear    = true,
    units        = 'metric', -- 'metric' | 'imperial'
    scale        = 1.0,      -- 0.7 - 1.4
    opacity      = 1.0,      -- 0.3 - 1.0
}

Config.Locale = {
    waypoint        = 'Waypoint',
    arrived         = 'Arrived',
    waypointSet     = 'Waypoint set',
    waypointCleared = 'Waypoint cleared',
    allCleared      = 'All waypoints cleared',
    enabled         = '3D waypoints on',
    disabled        = '3D waypoints off',
    unknownLocation = 'Unknown location',
    keybind         = 'Open waypoint settings',

    ui = {
        title    = '3D Waypoint',
        subtitle = 'Display & behaviour',
        close    = 'to close',
        reset    = 'Reset',
        done     = 'Done',
        preview  = 'Preview',
        groups   = {
            display    = 'Display',
            behaviour  = 'Behaviour',
            appearance = 'Appearance',
        },
        units = {
            metric   = 'Metric',
            imperial = 'Imperial',
        },
        settings = {
            enabled      = { 'Show waypoints',        'Render markers in the world' },
            offscreen    = { 'Off-screen indicators', 'Point to waypoints behind you' },
            showStreet   = { 'Street name',           'Shown when you look at a marker' },
            showEta      = { 'Arrival time',          'Estimated from your current speed' },
            groundMarker = { 'Ground beam',           'Light pillar at the destination' },
            autoClear    = { 'Clear on arrival',      'Remove the waypoint when reached' },
            units        = { 'Units',                 'Distance format' },
            scale        = { 'Size',                  'Marker scale' },
            opacity      = { 'Opacity',               'Overall HUD visibility' },
        },
    },
}
