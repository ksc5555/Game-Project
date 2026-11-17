# Demon War - siege lane prototype (v0.3)

Original Godot 4 code (GDScript). Kingdom is the inspiration for the feel only;
no code from noio/kingdom is used.

## Run it
1. Install Godot 4.3 or newer (standard build, not .NET).
2. Open Godot, press Import, pick `project.godot` in this folder.
3. Press F5.

## Controls
| Key | Action |
|---|---|
| A / D (or arrows) | Move |
| Shift | Sprint |
| Space (hold) | Attack |
| S (hold) | Block (takes 75% less damage, can't move) |
| E (hold) | Pay coins into the plot you are standing at |
| N | Skip to night |
| R | Restart after victory or defeat |

## Rules in this build
- Survive 5 nights. You lose when the Keep falls.
- Coins: 10 to start, 4 at each dawn, drops from dead demons. Walk over coins to pick them up.
- Plots: stand on one, hold E. Builders walk out and build it (daytime only), and repair damage by day.
- Wall has 3 levels. Barracks -> soldier, Archery Range -> archer, Church -> priest, Mage Tower -> mage.
- Archers climb the Archer Tower (2 places), mages the Mage Tower (2 places). Soldiers hold the wall. Priests heal.
- Your party of 4 (you + spear soldier, archer, priest) follows you. Party members pick skills at random off cooldown.
- A dead unit drops 1 coin. Party members come back at dawn. You respawn at the Keep after 6 seconds.
- Demons only come at night, from the right. Thralls swarm; War Clan brutes are slow and smash structures.
- Daylight burns any demon still alive.

## Where things are
- `scripts/cfg.gd` - every tuning number (health, damage, costs, wave sizes, day length, building positions).
- `scripts/main.gd` - builds the lane, runs coins, day/night, waves, win/lose.
- `scripts/unit.gd` - shared base: sprite, fake animation, health bar.
- `scripts/player.gd`, `ally.gd`, `demon.gd`, `builder.gd` - behaviour of each kind of unit.
- `scripts/building.gd` - plots, paying, building, placeholder drawing.
- `art/units/` - the cleaned sprites (transparent, 1 art pixel = 1 px, about 40 px tall).

## Art in v0.3
- Units: only the animated soldiers (walk / attack / block sheets in `art/anim/`). You, your 3 party soldiers, garrison soldiers and builders all use them.
- Demons: War Clan and Lesser Thrall clean sprites (single frames).
- Buildings: Tavern (the Keep), Church, Barracks, Mage Tower, Archer Tower, Palisade wall, campfire. Backdrop: dusk ruins.
- Only the Barracks recruits for now (soldiers). Archery Range and Thieves' Guild are locked placeholders.

## Placeholder (to be replaced by real art)
Archery Range and Thieves' Guild (boxes), coins, projectiles, effects. Builders are tinted soldiers.

## Old placeholder notes
Buildings, backdrop, coins, projectiles, effects, the builder (a tinted monk), and all animation
(units are a single still frame; bob, lunge, hit flash and topple are done in code).

## Self-test (optional)
`DW_AUTOTEST=1 godot --headless --path . --fixed-fps 60` plays a whole game by itself and prints the result.
