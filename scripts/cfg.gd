extends RefCounted
# ---------------------------------------------------------------
# Every tuning number in the prototype lives in this one file.
# Change a value, press F5, feel the difference.
# ---------------------------------------------------------------

# --- World (pixels; x grows to the right, ground is y = 0) ---
const WORLD_LEFT := -880.0
const WORLD_RIGHT := 1060.0
const SPAWN_X := 1010.0         # demons walk in from here

# --- Day / night ---
const DAY_LEN := 60.0           # seconds of daylight
const NIGHT_LEN := 55.0         # seconds of night
const NIGHTS_TO_WIN := 5
const SUN_BURN := 7.0           # damage per second to demons caught by daylight

# --- Coins ---
const START_COINS := 10
const DAWN_PAYOUT := 4
const PAY_INTERVAL := 0.16      # seconds between coins while holding E

# --- Player ---
const PLAYER := {
	"anim": "soldier", "sprite": "soldier_sword", "hp": 70.0, "walk": 58.0, "sprint": 98.0,
	"dmg": 7.0, "atk_cd": 0.42, "atk_range": 28.0, "knock": 5.0, "max_hits": 2,
	"regen": 1.0, "respawn": 6.0,
}

# --- Party that follows the player (role, sprite) ---
const PARTY := [
	["soldier", "anim:soldier2"],
	["soldier", "anim:soldier_f"],
	["soldier", "anim:soldier2"],
]
const PARTY_HP_MULT := 1.2

# --- Garrison units ---
const UNITS := {
	"soldier": {"hp": 40.0, "speed": 44.0, "cost": 2, "cap": 6, "sprites": ["anim:soldier2", "anim:soldier_f"]},
	"archer":  {"hp": 22.0, "speed": 46.0, "cost": 2, "cap": 4, "sprites": ["archer"]},
	"priest":  {"hp": 22.0, "speed": 40.0, "cost": 3, "cap": 2, "sprites": ["priest_m", "priest_f"]},
	"mage":    {"hp": 20.0, "speed": 40.0, "cost": 3, "cap": 2, "sprites": ["mage"]},
}

# --- Skills. Garrison units only use the first one. Party members pick
#     at random from whatever is off cooldown and has a valid target. ---
const SKILLS := {
	"soldier": [
		{"name": "Strike", "kind": "melee", "cd": 1.0, "dmg": 6.0, "rng": 30.0},
		{"name": "Shield Bash", "kind": "bash", "cd": 6.0, "dmg": 4.0, "rng": 26.0, "knock": 26.0, "stun": 1.2},
		{"name": "Cleave", "kind": "cleave", "cd": 7.0, "dmg": 6.0, "rng": 30.0},
	],
	"archer": [
		{"name": "Shot", "kind": "arrow", "cd": 1.5, "dmg": 6.0, "rng": 150.0},
		{"name": "Volley", "kind": "volley", "cd": 7.0, "dmg": 5.0, "rng": 150.0, "count": 3},
		{"name": "Piercing Shot", "kind": "pierce", "cd": 9.0, "dmg": 8.0, "rng": 130.0},
	],
	"priest": [
		{"name": "Heal", "kind": "heal", "cd": 2.6, "amt": 9.0, "rng": 110.0},
		{"name": "Blessing", "kind": "bless", "cd": 10.0, "amt": 6.0, "radius": 70.0},
		{"name": "Smite", "kind": "smite", "cd": 4.5, "dmg": 7.0, "rng": 120.0},
	],
	"mage": [
		{"name": "Fireball", "kind": "fireball", "cd": 3.4, "dmg": 9.0, "rng": 170.0, "radius": 24.0},
		{"name": "Frost", "kind": "frost", "cd": 9.0, "dmg": 3.0, "rng": 150.0, "radius": 36.0, "dur": 3.0},
	],
}
const TOWER_RANGE_BONUS := 35.0

# --- Demons ---
const DEMONS := {
	"thrall":  {"sprite": "thrall",  "hp": 20.0, "speed": 34.0, "dmg": 5.0, "atk_cd": 0.9, "reach": 14.0, "struct_mult": 0.7, "coins": 1, "coin_chance": 0.7},
	"warclan": {"sprite": "warclan", "hp": 110.0, "speed": 21.0, "dmg": 14.0, "atk_cd": 1.4, "reach": 16.0, "struct_mult": 2.5, "coins": 2, "coin_chance": 1.0},
}

# Wave for night n (1-based). Returns how many of each demon.
static func wave(n: int) -> Dictionary:
	return {"thrall": 6 + 5 * n, "warclan": maxi(0, n - 1) + (1 if n >= NIGHTS_TO_WIN else 0)}

# Demons arrive in packs, not a steady trickle. Packs per night:
static func packs(n: int) -> int:
	return 2 + n / 2

# --- Buildings. "art" = PNG in art/buildings (bottom-centre sits on the ground).
#     Buildings without art are drawn as placeholder boxes.
#     levels = one entry per level: coin cost, hit points, height (placeholders only), build seconds.
#     post = where a unit stands on top: [x offset from centre, height above ground].
const BUILD_REPAIR_RATE := 14.0
const BUILDINGS := {
	"keep": {"name": "Tavern (Keep)", "x": -110.0, "art": "tavern", "blocks": true, "start_built": true,
		"levels": [{"cost": 0, "hp": 500.0, "h": 0.0, "time": 0.0}]},
	"wall": {"name": "Palisade", "x": 500.0, "art": "palisade", "blocks": true,
		"levels": [
			{"cost": 3, "hp": 140.0, "h": 40.0, "time": 4.0},
			{"cost": 6, "hp": 320.0, "h": 52.0, "time": 6.0},
			{"cost": 10, "hp": 600.0, "h": 64.0, "time": 8.0}]},
	"archer_tower": {"name": "Archer Tower", "x": 380.0, "art": "archer_tower", "blocks": true, "slots": 1, "post": [0.0, 86.0],
		"levels": [{"cost": 4, "hp": 160.0, "h": 0.0, "time": 6.0}]},
	"mage_tower": {"name": "Mage Tower", "x": 250.0, "art": "mage_tower", "blocks": true, "slots": 1, "post": [30.0, 84.0],
		"levels": [{"cost": 6, "hp": 160.0, "h": 0.0, "time": 8.0}]},
	"barracks": {"name": "Barracks", "x": -370.0, "art": "barracks", "recruit": "soldier",
		"levels": [{"cost": 3, "hp": 200.0, "h": 0.0, "time": 5.0}]},
	"church": {"name": "Church", "x": -530.0, "art": "church",
		"levels": [{"cost": 4, "hp": 200.0, "h": 0.0, "time": 6.0}]},
	"range": {"name": "Archery Range (later)", "x": -660.0, "w": 50.0, "color": Color(0.34, 0.36, 0.24), "locked": true,
		"levels": [{"cost": 3, "hp": 200.0, "h": 20.0, "time": 5.0}]},
	"guild": {"name": "Thieves' Guild (later)", "x": -760.0, "w": 40.0, "color": Color(0.25, 0.25, 0.28), "locked": true,
		"levels": [{"cost": 99, "hp": 200.0, "h": 30.0, "time": 6.0}]},
}
const PROPS := [["campfire", 110.0]]
const BLOCK_REDUCTION := 0.75   # damage blocked while holding the block key
