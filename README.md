# Brainrot Bay

A 3D Steal-a-Brainrot game for make.fun's roblox-brainrot-01 bounty, built in
Roblox's 3D world under a 3D camera, with a ScreenGui interface on top.

The loop: a conveyor belt carries original brainrot characters across a sand
island. Walk up to the belt and press **E** to buy one, and it goes to a stand
on your base and starts earning money every second. Press **E** beside another
player's brainrot to steal it — then run home with it before they slap you
(**Q**) and make you drop it. Press **F** to lock your base. Spend earnings in
the shop (walk speed, slap power, earnings, lock time, faster stealing), and
rebirth for a permanent +25% earnings each time. Every three minutes a tsunami
sweeps the island: get to your base or be knocked flat.

- 15 original brainrots across 6 rarities (Common to Secret), with 5 mutations
  (Golden, Diamond, Lava, Rainbow, Ghost) that multiply their $/s.
- 8 coloured bases in a ring around the island, 5 stands each.
- `main.ts` (Node 22, standard library only) hands the game in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output`, leaving out
  every name that starts with a dot (such as `.gitkeep` or `.DS_Store`, which
  fail an entry), and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`;
  `screenshots/` holds four renders of the game; `PLAY.json` names the
  published place once the experience is public.
- `01-cover.png` is the game's thumbnail on Roblox: the same picture, uploaded
  on the Creator Dashboard with the game's icon.
- `TOUR.json` is the optional tour: for each screenshot, the keys that bring
  the game to that screen.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt,
which gives every command in order (Before you submit, then Enter).
