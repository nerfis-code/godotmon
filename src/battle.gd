class_name Battle
extends RefCounted

signal initdone
const IGNORE = [
	"t:",
	"gametype",
	"player",
	"",
	"gen",
	"tier",
	"rule",
	"teamsize",
]
var sim_controller: SimController
var my_side: Dictionary

func _init() -> void:
	sim_controller = SimController.new(_on_message_received)

func _on_message_received(message: String) -> void:
	var parts = message.split("|")
	
	if parts[1] == "request":
		var data = JSON.parse_string(parts[2])
		var p := PokemonServer.new(data.side.pokemon[0])
		my_side = {pokemon = [p]}
		initdone.emit()
		
	print(parts)


class PokemonServer:
	var ident: String
	var details: String
	var condition: String
	var active: bool
	var reviving: bool
	var stats: Dictionary
	var moves: Array[String] = []
	var baseAbility: String
	var ability: String = ""
	var item: String
	var pokeball: String
	var teraType: String
	var terastallized: String = ""

	func _init(json_data: Dictionary):
		for i in get_property_list():
			if not (i.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue

			if i.type == TYPE_ARRAY:
				moves.append_array(json_data[i.name])
			else:
				set(i.name, json_data[i.name])

# interface Resquest {
#   active: Active[]
#   side: Side
# }

# interface Active {
#   moves: Move[]
#   canTerastallize: string
# }

# interface Move {
#   move: string
#   id: string
#   pp: number
#   maxpp: number
#   target: string
#   disabled: boolean
# }

# interface Side {
#   name: string
#   id: string
#   pokemon: Pokemon[]
# }

# interface Pokemon {
#   ident: string
#   details: string
#   condition: string
#   active: boolean
#   stats: Stats
#   moves: string[]
#   baseAbility: string
#   item: string
#   pokeball: string
#   ability: string
#   commanding: boolean
#   reviving: boolean
#   teraType: string
#   terastallized: string
# }

# interface Stats {
#   atk: number
#   def: number
#   spa: number
#   spd: number
#   spe: number
# }
