[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Razzshare102/brainrot-bay/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Razzshare102/brainrot-bay/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

# Brainrot Bay

A 3D Steal-a-Brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01), built
as a Rojo project. A sandy island ringed by eight coloured bases, a conveyor belt down the middle, and a tsunami that
sweeps the island every three minutes.

## How it plays

- A belt spawns original brainrot characters. Stand by it and press **E** to buy the front one.
- Each brainrot earns money every second on your base. Rarer ones earn more; mutations multiply the rate.
- Press **E** next to a rival's brainrot to steal it — then run it home before the timer ends, or a slap sends it back.
- **Q** slaps the nearest rival (and drops whatever they are carrying). **F** locks your base for 30 seconds.
- Spend in the shop: faster shoes, a stronger slap, extra base slots, income boosts. **Rebirth** for +25% income.

## Layout

- `src/shared/` — the catalogue (15 characters, 6 rarities, 5 mutations) and the tuning numbers.
- `src/server/` — the belt, the bases and money, the shop, stealing and slapping, the tsunami.
- `src/client/` — the HUD and the key/button handling.
- `default.project.json` — the island itself: water, sand, belt, eight bases, palms, rocks, lamps.
- `main.ts` — hands the game in: copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes
  `/output/dossier.json` with the vendored make.fun library.

## Build

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`PLAY.json` still names no place: publish the experience from Roblox Studio, set it Public, and fill in the real
`place_id` and `universe_id` before submitting.
