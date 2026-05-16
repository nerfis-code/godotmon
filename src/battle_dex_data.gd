extends RefCounted

const BATTLE_NATURES = {
	"Adamant": {
		"plus": "atk",
		"minus": "spa",
	},
	"Bashful": {},
	"Bold": {
		"plus": "def",
		"minus": "atk",
	},
	"Brave": {
		"plus": "atk",
		"minus": "spe",
	},
	"Calm": {
		"plus": "spd",
		"minus": "atk",
	},
	"Careful": {
		"plus": "spd",
		"minus": "spa",
	},
	"Docile": {},
	"Gentle": {
		"plus": "spd",
		"minus": "def",
	},
	"Hardy": {},
	"Hasty": {
		"plus": "spe",
		"minus": "def",
	},
	"Impish": {
		"plus": "def",
		"minus": "spa",
	},
	"Jolly": {
		"plus": "spe",
		"minus": "spa",
	},
	"Lax": {
		"plus": "def",
		"minus": "spd",
	},
	"Lonely": {
		"plus": "atk",
		"minus": "def",
	},
	"Mild": {
		"plus": "spa",
		"minus": "def",
	},
	"Modest": {
		"plus": "spa",
		"minus": "atk",
	},
	"Naive": {
		"plus": "spe",
		"minus": "spd",
	},
	"Naughty": {
		"plus": "atk",
		"minus": "spd",
	},
	"Quiet": {
		"plus": "spa",
		"minus": "spe",
	},
	"Quirky": {},
	"Rash": {
		"plus": "spa",
		"minus": "spd",
	},
	"Relaxed": {
		"plus": "def",
		"minus": "spe",
	},
	"Sassy": {
		"plus": "spd",
		"minus": "spe",
	},
	"Serious": {},
	"Timid": {
		"plus": "spe",
		"minus": "atk",
	},
}

const BATTLE_STAT_IDS = {
	"HP": "hp",
	"hp": "hp",
	"Atk": "atk",
	"atk": "atk",
	"Def": "def",
	"def": "def",
	"SpA": "spa",
	"SAtk": "spa",
	"SpAtk": "spa",
	"spa": "spa",
	"spc": "spa",
	"Spc": "spa",
	"SpD": "spd",
	"SDef": "spd",
	"SpDef": "spd",
	"spd": "spd",
	"Spe": "spe",
	"Spd": "spe",
	"spe": "spe",
}

const BATTLE_STAT_NAMES = {
	"hp": "HP",
	"atk": "Atk",
	"def": "Def",
	"spa": "SpA",
	"spd": "SpD",
	"spe": "Spe",
}

const BATTLE_BASE_SPECIES_CHART = [
	"unown", "burmy", "shellos", "gastrodon", "deerling", "sawsbuck",
	"vivillon", "flabebe", "floette", "florges", "furfrou", "minior",
	"alcremie", "tatsugiri", "pokestarufo", "pokestarbrycenman",
	"pokestarmt", "pokestarmt2", "pokestartransport", "pokestargiant",
	"pokestarhumanoid", "pokestarmonster", "pokestarf00", "pokestarf002",
	"pokestarspirit", "pokestarblackdoor", "pokestarwhitedoor", "pokestarblackbelt",
]

class Effect:
	var id
	var name: String
	var gen: int
	var effect_type: String
	var exists: bool

class PureEffect extends Effect:
	func _init(_id, _name: String):
		id = _id
		name = _name
		gen = 0
		exists = false
		effect_type = "PureEffect"

class Item extends Effect:
	var num: int
	var spritenum: int
	var desc: String
	var short_desc: String

	var mega_stone
	var z_move
	var z_move_type: String
	var z_move_from: String
	var z_move_user
	var on_plate: String
	var on_memory: String
	var on_drive: String
	var fling
	var natural_gift
	var is_pokeball: bool
	var item_user

	func _init(_id, _name: String, data):
		if not data or typeof(data) != TYPE_DICTIONARY:
			data = {}

		if data.has("name"):
			_name = data.name

		name = Dex.sanitize_name(_name)
		id = _id
		gen = data.get("gen", 0)
		exists = bool(data.exists) if data.has("exists") else true

		effect_type = "Item"

		num = data.get("num", 0)
		spritenum = data.get("spritenum", 0)
		desc = data.get("desc", data.get("shortDesc", ""))
		short_desc = data.get("shortDesc", desc)

		mega_stone = data.get("megaStone", null)
		z_move = data.get("zMove", null)
		z_move_type = data.get("zMoveType", "")
		z_move_from = data.get("zMoveFrom", "")
		z_move_user = data.get("zMoveUser", null)
		on_plate = data.get("onPlate", "")
		on_memory = data.get("onMemory", "")
		on_drive = data.get("onDrive", "")
		fling = data.get("fling", null)
		natural_gift = data.get("naturalGift", null)
		is_pokeball = bool(data.get("isPokeball", false))
		item_user = data.get("itemUser", null)

		if gen == 0:
			if num >= 577:
				gen = 6
			elif num >= 537:
				gen = 5
			elif num >= 377:
				gen = 4
			else:
				gen = 3

class MoveFlags:
	# The move has an animation when used on an ally.
	var ally_anim: int = 0
	# Power is multiplied by 1.5 when used by a Pokemon with the Strong Jaw Ability.
	var bite: int = 0
	# Has no effect on Pokemon with the Bulletproof Ability.
	var bullet: int = 0
	# Ignores a target's substitute.
	var bypass_sub: int = 0
	# The user is unable to make a move between turns.
	var charge: int = 0
	# Makes contact.
	var contact: int = 0
	# When used by a Pokemon, other Pokemon with the Dancer Ability can attempt to execute the same move.
	var dance: int = 0
	# Thaws the user if executed successfully while the user is frozen.
	var defrost: int = 0
	# Can target a Pokemon positioned anywhere in a Triple Battle.
	var distance: int = 0
	# Prevented from being executed or selected during Gravity's effect.
	var gravity: int = 0
	# Prevented from being executed or selected during Heal Block's effect.
	var heal: int = 0
	# Can be copied by Mirror Move.
	var mirror: int = 0
	# Prevented from being executed or selected in a Sky Battle.
	var nonsky: int = 0
	# Cannot be copied by Sketch
	var no_sketch: int = 0
	# Has no effect on Grass-type Pokemon, Pokemon with the Overcoat Ability, and Pokemon holding Safety Goggles.
	var powder: int = 0
	# Blocked by Detect, Protect, Spiky Shield, and if not a Status move, King's Shield.
	var protect: int = 0
	# Power is multiplied by 1.5 when used by a Pokemon with the Mega Launcher Ability.
	var pulse: int = 0
	# Power is multiplied by 1.2 when used by a Pokemon with the Iron Fist Ability.
	var punch: int = 0
	# If this move is successful, the user must recharge on the following turn and cannot make a move.
	var recharge: int = 0
	# Bounced back to the original user by Magic Coat or the Magic Bounce Ability.
	var reflectable: int = 0
	# Power is multiplied by 1.5 when used by a Pokemon with the Sharpness Ability.
	var slicing: int = 0
	# Can be stolen from the original user and instead used by another Pokemon using Snatch.
	var snatch: int = 0
	# Has no effect on Pokemon with the Soundproof Ability.
	var sound: int = 0
	# Activates the effects of the Wind Power and Wind Rider Abilities.
	var wind: int = 0

class Move extends Effect:
	var base_power: int
	var accuracy
	var pp: int
	var type: String
	var category: String
	var priority: int
	var target: String
	var pressure_target: String
	var flags
	var crit_ratio: int
	var damage: int

	var desc: String
	var short_desc: String
	var is_nonstandard
	var is_z
	var z_move = {}
	var is_max
	var max_move = {"base_power": 0}
	var ohko
	var recoil
	var heal
	var multihit
	var has_crash_damage: bool
	var base_power_callback: bool
	var no_pp_boosts: bool
	var status: String
	var secondaries
	var num: int

	func _init(_id, _name: String, data):
		if not data or typeof(data) != TYPE_DICTIONARY:
			data = {}

		if data.has("name"):
			_name = data.name

		name = Dex.sanitize_name(_name)
		id = _id
		gen = data.get("gen", 0)
		exists = bool(data.exists) if data.has("exists") else true

		effect_type = "Move"

		base_power = data.get("basePower", 0)
		accuracy = data.get("accuracy", 0)
		pp = data.get("pp", 1)
		type = data.get("type", "???")
		category = data.get("category", "Physical")
		priority = data.get("priority", 0)
		target = data.get("target", "normal")
		pressure_target = data.get("pressureTarget", target)
		flags = data.get("flags", {})
		crit_ratio = 0 if data.get("critRatio") == 0 else data.get("critRatio", 1)
		damage = data.get("damage")

		# textos
		desc = data.get("desc")
		short_desc = data.get("shortDesc")
		is_nonstandard = data.get("isNonstandard", null)
		is_z = data.get("isZ", "")
		z_move = data.get("zMove", {})
		ohko = data.get("ohko", null)
		recoil = data.get("recoil", null)
		heal = data.get("heal", null)
		multihit = data.get("multihit", null)
		has_crash_damage = data.get("hasCrashDamage", false)
		base_power_callback = bool(data.get("basePowerCallback", false))
		no_pp_boosts = data.get("noPPBoosts", false)
		status = data.get("status", "")
		secondaries = data.get("secondaries", data.get("secondary", null) and [data.secondary] or null)

		is_max = data.get("isMax", false)
		max_move = data.get("maxMove", {"base_power": 0})

		if category != "Status" and not max_move.get("base_power"):
			if is_z or is_max:
				max_move = {"base_power": 1}
			elif not base_power:
				max_move = {"base_power": 100}
			elif type in ["Fighting", "Poison"]:
				if base_power >= 150:
					max_move = {"base_power": 100}
				elif base_power >= 110:
					max_move = {"base_power": 95}
				elif base_power >= 75:
					max_move = {"base_power": 90}
				elif base_power >= 65:
					max_move = {"base_power": 85}
				elif base_power >= 55:
					max_move = {"base_power": 80}
				elif base_power >= 45:
					max_move = {"base_power": 75}
				else:
					max_move = {"base_power": 70}
			else:
				if base_power >= 150:
					max_move = {"base_power": 150}
				elif base_power >= 110:
					max_move = {"base_power": 140}
				elif base_power >= 75:
					max_move = {"base_power": 130}
				elif base_power >= 65:
					max_move = {"base_power": 120}
				elif base_power >= 55:
					max_move = {"base_power": 110}
				elif base_power >= 45:
					max_move = {"base_power": 100}
				else:
					max_move = {"base_power": 90}

		if category != "Status" and not is_z and not is_max:
			var bp = base_power
			z_move = {}

			if typeof(multihit) == TYPE_ARRAY:
				bp *= 3

			if not bp:
				z_move["base_power"] = 100
			elif bp >= 140:
				z_move["base_power"] = 200
			elif bp >= 130:
				z_move["base_power"] = 195
			elif bp >= 120:
				z_move["base_power"] = 190
			elif bp >= 110:
				z_move["base_power"] = 185
			elif bp >= 100:
				z_move["base_power"] = 180
			elif bp >= 90:
				z_move["base_power"] = 175
			elif bp >= 80:
				z_move["base_power"] = 160
			elif bp >= 70:
				z_move["base_power"] = 140
			elif bp >= 60:
				z_move["base_power"] = 120
			else:
				z_move["base_power"] = 100

			if data.has("zMove"):
				z_move["base_power"] = data.zMove.basePower

		num = data.get("num", 0)

		if gen == 0:
			if num >= 743:
				gen = 8
			elif num >= 622:
				gen = 7
			elif num >= 560:
				gen = 6
			elif num >= 468:
				gen = 5
			elif num >= 355:
				gen = 4
			elif num >= 252:
				gen = 3
			elif num >= 166:
				gen = 2
			elif num >= 1:
				gen = 1

class AbilityFlags:
	# Can be suppressed by Mold Breaker and related effects
	var breakable: int = 0
	# Ability can't be suppressed by e.g. Gastro Acid or Neutralizing Gas
	var cant_suppress: int = 0
	# Role Play fails if target has this Ability
	var fail_role_play: int = 0
	# Skill Swap fails if either the user or target has this Ability
	var fail_skill_swap: int = 0
	# Entrainment fails if user has this Ability
	var no_entrain: int = 0
	# Receiver and Power of Alchemy will not activate if an ally faints with this Ability
	var no_receiver: int = 0
	# Trace cannot copy this Ability
	var no_trace: int = 0
	# Disables the Ability if the user is Transformed
	var no_transform: int = 0

class Ability extends Effect:
	var num: int
	var short_desc: String
	var desc: String

	var rating: int
	var flags
	var is_nonstandard: bool

	func _init(_id, _name: String, data):
		if not data or typeof(data) != TYPE_DICTIONARY:
			data = {}

		if data.has("name"):
			_name = data.name

		name = Dex.sanitize_name(_name)
		id = _id
		gen = data.get("gen", 0)
		exists = bool(data.exists) if data.has("exists") else true

		effect_type = "Ability"

		num = data.get("num", 0)
		short_desc = data.get("shortDesc", data.get("desc", ""))
		desc = data.get("desc", data.get("shortDesc", ""))

		rating = data.get("rating", 1)
		flags = data.get("flags", {})
		is_nonstandard = bool(data.get("isNonstandard", false))

		if gen == 0:
			if num >= 234:
				gen = 8
			elif num >= 192:
				gen = 7
			elif num >= 165:
				gen = 6
			elif num >= 124:
				gen = 5
			elif num >= 77:
				gen = 4
			elif num >= 1:
				gen = 3

class Species extends Effect:
	# name / forme data
	var base_species: String
	var forme: String
	var forme_id: String
	var sprite_id: String
	var base_forme: String

	# basic data
	var num: int
	var types
	var abilities
	var base_stats
	var bst: int
	var weight_kg: float

	# flavor data
	var height_m: float
	var gender: String
	var color: String
	var gender_ratio
	var egg_groups
	var tags

	# format data
	var other_formes
	var cosmetic_formes
	var evos
	var prevo: String
	var evo_type: String
	var evo_level: int
	var evo_move: String
	var evo_item: String
	var evo_condition: String
	var nfe: bool
	var required_items
	var tier: String

	var is_totem: bool
	var is_mega: bool
	var is_primal: bool
	var can_gigantamax: bool
	var cannot_dynamax: bool
	var required_tera_type: String
	var battle_only
	var unreleased_hidden
	var changes_from: String

	func _init(_id, _name: String, data):
		if not data or typeof(data) != TYPE_DICTIONARY:
			data = {}

		if data.has("name"):
			_name = data.name

		name = Dex.sanitize_name(_name)
		id = _id
		gen = data.get("gen", 0)
		exists = bool(data.exists) if data.has("exists") else true

		effect_type = "Species"

		base_species = data.get("baseSpecies", _name)
		forme = data.get("forme", "")

		var base_id = Utils.to_id(base_species)
		forme_id = "" if base_id == id else "-" + Utils.to_id(forme)
		sprite_id = base_id + forme_id

		if sprite_id.ends_with("totem"):
			sprite_id = sprite_id.substr(0, sprite_id.length() - 5)

		if sprite_id == "greninja-bond":
			sprite_id = "greninja"
		elif sprite_id == "rockruff-dusk":
			sprite_id = "rockruff"

		if sprite_id.ends_with("-"):
			sprite_id = sprite_id.substr(0, sprite_id.length() - 1)

		base_forme = data.get("baseForme", "")

		num = data.get("num", 0)
		types = data.get("types", ["???"])
		abilities = data.get("abilities", {0: "No Ability"})
		base_stats = data.get("baseStats", {
			"hp": 0, "atk": 0, "def": 0,
			"spa": 0, "spd": 0, "spe": 0
		})

		bst = base_stats.hp + base_stats.atk + base_stats.def + \
			  base_stats.spa + base_stats.spd + base_stats.spe

		weight_kg = data.get("weightkg", 0)

		height_m = data.get("heightm", 0)
		gender = data.get("gender", "")
		color = data.get("color", "")
		gender_ratio = data.get("genderRatio", null)
		egg_groups = data.get("eggGroups", [])
		tags = data.get("tags", [])

		other_formes = data.get("otherFormes", null)
		cosmetic_formes = data.get("cosmeticFormes", null)
		evos = data.get("evos", null)

		prevo = data.get("prevo", "")
		evo_type = data.get("evoType", "")
		evo_level = data.get("evoLevel", 0)
		evo_move = data.get("evoMove", "")
		evo_item = data.get("evoItem", "")
		evo_condition = data.get("evoCondition", "")

		nfe = data.get("nfe", false)
		required_items = data.get("requiredItems", data.get("requiredItem", []))
		tier = data.get("tier", "")

		is_totem = false
		is_mega = forme_id in ["-mega", "-megax", "-megay"]
		is_primal = forme_id == "-primal"

		can_gigantamax = bool(data.get("canGigantamax", false))
		cannot_dynamax = bool(data.get("cannotDynamax", false))
		required_tera_type = data.get("requiredTeraType", "")
		battle_only = data.get("battleOnly", base_species if is_mega else null)

		unreleased_hidden = data.get("unreleasedHidden", false)
		changes_from = data.get("changesFrom", battle_only if battle_only != base_species else base_species)

		if gen == 0:
			if num >= 906 or forme_id.begins_with("-paldea"):
				gen = 9
			elif num >= 810 or forme_id.begins_with("-galar") or forme_id.begins_with("-hisui"):
				gen = 8
			elif num >= 722 or forme_id == "-alola" or forme_id == "-starter":
				gen = 7
			elif is_mega or is_primal:
				gen = 6
				battle_only = base_species
			elif forme_id == "-totem" or forme_id == "-alolatotem":
				gen = 7
				is_totem = true
			elif num >= 650:
				gen = 6
			elif num >= 494:
				gen = 5
			elif num >= 387:
				gen = 4
			elif num >= 252:
				gen = 3
			elif num >= 152:
				gen = 2
			elif num >= 1:
				gen = 1

class Type extends Effect:
	# Damage interactions (matchups)
	var damage_taken: Dictionary = {}

	# Hidden Power IV modifiers
	var hp_ivs: Dictionary = {}

	# Hidden Power DV modifiers
	var hp_dvs: Dictionary = {}
