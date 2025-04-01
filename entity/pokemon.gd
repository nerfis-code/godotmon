class_name Pokemon

var species_name: String
var species
var level: int
var abilities: String
var form_index: int = 0
var name: String
var primary_type: String
var secondary_type: String
const stats_fields = {
		"ps": 0,
		"attack": 0,
		"defense": 0,
		"speed": 0,
		"sp_attack": 0,
		"sp_defense": 0
	}
var stats = DynamicObject.new(stats_fields.duplicate())
	# 31
var iv = DynamicObject.new(stats_fields.duplicate())
	# 256
var ev = DynamicObject.new(stats_fields.duplicate())
var moves = []
enum { PS, ATK, DEF, SPD, SP_ATK, SP_DEF }
func calculate_stats():

	var _level = float(level)
	stats.ps = 10+( _level/100 * ((species.baseStats[PS]*2)+iv.ps*4)) + _level + _level *ev.ps/100
	
	stats.attack = 5+( _level /100 * ((species.baseStats[ATK]*2)+iv.attack*4)) + _level *ev.attack/100
	stats.defense = 5+( _level /100 * ((species.baseStats[DEF]*2)+iv.defense*4)) + _level *ev.defense/100
	stats.speed = 5+( _level /100 * ((species.baseStats[SPD]*2)+iv.speed*4)) + _level *ev.speed/100
	stats.sp_attack = 5+( _level /100 * ((species.baseStats[SP_ATK]*2)+iv.sp_attack*4)) + _level *ev.sp_attack/100
	stats.sp_defense = 5+( _level /100 * ((species.baseStats[SP_DEF]*2)+iv.sp_defense*4)) + _level *ev.sp_defense/100


func _to_string() -> String:
	var type_str = primary_type
	if secondary_type != "":
		type_str += "/%s" % secondary_type
	
	var moves_str = ""
	for move in moves:
		if move != null:
			moves_str += "\n  - %s (%d/%d)" % [move.name, move.current_pp, move.total_pp]
		else:
			moves_str += "\n  - Empty"
	
	return """Pokemon Data:
Name: {name} (Lv. {level})
Species: {species_name} [Form: {form}]
Types: {types}
Abilities: {abilities}

Base Stats:
  HP: {hp} | ATK: {atk} | DEF: {def} | SPA: {spa} | SPD: {spd} | SPE: {spe}
IVs: {iv_hp}/{iv_atk}/{iv_def}/{iv_spa}/{iv_spd}/{iv_spe}
EVs: {ev_hp}/{ev_atk}/{ev_def}/{ev_spa}/{ev_spd}/{ev_spe}

Moves:{moves}
""".format({
	"name": name,
	"level": level,
	"species_name": species_name,
	"form": form_index,
	"types": type_str,
	"abilities": abilities,
	
	"hp": stats.ps,
	"atk": stats.attack,
	"def": stats.defense,
	"spa": stats.sp_attack,
	"spd": stats.sp_defense,
	"spe": stats.speed,
	
	"iv_hp": iv.ps,
	"iv_atk": iv.attack,
	"iv_def": iv.defense,
	"iv_spa": iv.sp_attack,
	"iv_spd": iv.sp_defense,
	"iv_spe": iv.speed,
	
	"ev_hp": ev.ps,
	"ev_atk": ev.attack,
	"ev_def": ev.defense,
	"ev_spa": ev.sp_attack,
	"ev_spd": ev.sp_defense,
	"ev_spe": ev.speed,
	
	"moves": moves_str
})
