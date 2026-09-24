# rr-3dwaypoint

A 3D waypoint HUD for FiveM with a monochrome glass look. It mirrors the GTA map waypoint and
exposes an API for custom waypoints (jobs, deliveries, missions, and so on).

## Features

- **3D marker** above the destination: icon, label and live distance.
- **Focus details**: look at a marker to expand it and see the street name and arrival time (ETA).
- **Off-screen indicators**: pinned to the screen edge with an arrow pointing at the target. Anything behind you shows on the bottom edge.
- **Ground beam and pulsing ring** in the world near the destination.
- **Arrival animation** and auto-clear, with a `rr-3dwaypoint:arrived` event.
- **Glass toasts** for waypoint set, cleared and arrived.
- **Settings panel** with a live preview. Settings are saved per player (KVP): units, size, opacity, and toggles for each feature.
- Scales with resolution (1080p → 4K), dims while aiming, and hides in the pause menu and cutscenes, when the HUD is hidden, and during screen fades.
- Sleeps at 300 ms when there are no waypoints.

## Install

1. Put the `rr-3dwaypoint` folder in `resources/`.
2. Add `ensure rr-3dwaypoint` to `server.cfg`.

## Commands

| Command       | Action                                       |
|---------------|----------------------------------------------|
| `/wp`         | Turn 3D waypoints on / off                   |
| `/wpsettings` | Open the settings panel (rebindable key)     |
| `/wpclear`    | Clear the map waypoint and all custom ones   |
| `/wptest`     | Demo waypoints (only with `Config.Debug`)    |

Change these in `config.lua`.

## API

### Client

```lua
exports['rr-3dwaypoint']:Add('delivery', {
    coords = vector3(-1037.8, -2737.6, 20.2), -- z = 0 → ground is found automatically
    label = 'Delivery',
    sublabel = 'Terminal 4',       -- optional; defaults to street + zone
    icon = 'box',                  -- pin, flag, star, home, car, box, briefcase, target, user, cross, dollar
    arriveDistance = 15.0,         -- optional
    removeOnArrive = true,         -- optional; nil = player's "Clear on arrival" setting
    groundMarker = true,           -- optional
    heightOffset = 1.0,            -- optional
})

exports['rr-3dwaypoint']:Remove('delivery')
exports['rr-3dwaypoint']:Clear()
exports['rr-3dwaypoint']:Has('delivery')      -- bool
exports['rr-3dwaypoint']:Get('delivery')      -- table | nil
exports['rr-3dwaypoint']:GetAll()             -- { ids }
exports['rr-3dwaypoint']:SetEnabled(true)
exports['rr-3dwaypoint']:IsEnabled()
exports['rr-3dwaypoint']:OpenSettings()

AddEventHandler('rr-3dwaypoint:arrived', function(id, label)
    -- id '__map' is the map waypoint
end)
```

### Server

```lua
exports['rr-3dwaypoint']:AddForPlayer(source, 'job', { coords = vector3(x, y, z), label = 'Job', icon = 'briefcase' })
exports['rr-3dwaypoint']:RemoveForPlayer(source, 'job')
exports['rr-3dwaypoint']:ClearForPlayer(-1) -- -1 = everyone
```

## Browser preview

Open `html/index.html` in a browser to see the UI with demo data outside the game.
Add `?settings` to open the panel straight away. The buttons in the bottom-left corner trigger a toast and an arrival.

## Notes

- NUI renders on top of the game frame, so `backdrop-filter` can't blur the game world. The
  glass look comes from layered translucent gradients, a lit top edge and soft shadows, so it
  looks the same in game as in the browser.
- The UI loads Inter and JetBrains Mono from Google Fonts. Without internet access it falls
  back to system fonts.
