extends Node

const BattleDexData = preload("uid://d1mlt2fddq0e8")

var items: Dictionary
var movedex: Dictionary
var abilities: Dictionary
var aliases: Dictionary
var pokedex: Dictionary
var alt_forms: Dictionary

var afd_mode = false

func _ready():
	var items_json = FileAccess.open("res://src/items.json", FileAccess.READ).get_as_text()
	items = JSON.parse_string(items_json)

	var moves_json = FileAccess.open("res://src/moves.json", FileAccess.READ).get_as_text()
	movedex = JSON.parse_string(moves_json)

	var abilities_json = FileAccess.open("res://src/abilities.json", FileAccess.READ).get_as_text()
	abilities = JSON.parse_string(abilities_json)

	var aliases_json = FileAccess.open("res://src/aliases.json", FileAccess.READ).get_as_text()
	aliases = JSON.parse_string(aliases_json)

	var pokedex_json = FileAccess.open("res://src/pokedex.json", FileAccess.READ).get_as_text()
	pokedex = JSON.parse_string(pokedex_json)

func get_item(name_or_item) -> BattleDexData.Item:
	# Si ya es un objeto (Item), devolverlo directamente
	if name_or_item != null and typeof(name_or_item) != TYPE_STRING:
		return name_or_item

	var name: String = name_or_item if name_or_item != null else ""
	var id: String = Utils.to_id(name_or_item)

	# Aliases
	if aliases.has(id):
			name = aliases[id]
			id = Utils.to_id(name)
		
	var data = items.get(id)

	# Si ya existe y es válido, devolverlo
	if typeof(data) == TYPE_DICTIONARY and data.get("exists") != null:
		return data

	# Crear datos por defecto si no existen
	if data == null:
		data = { "exists": false }

	var item = BattleDexData.Item.new(id, name, data)
	#items[id] = item

	return item


func get_effect(name) -> Variant:
	name = ("" if name == null else str(name)).strip_edges()

	if name.substr(0, 5) == "item:":
		return Dex.get_item(name.substr(5).strip_edges())
	elif name.substr(0, 8) == "ability:":
		return Dex.get_ability(name.substr(8).strip_edges())
	elif name.substr(0, 5) == "move:":
		return Dex.get_move(name.substr(5).strip_edges())

	var id: String = Utils.to_id(name)
	return BattleDexData.PureEffect.new(id, name)

func get_ability(name_or_ability):
	# Si ya es un objeto (Ability), devolverlo directamente
	if name_or_ability != null and typeof(name_or_ability) != TYPE_STRING:
		return name_or_ability

	var name: String = name_or_ability if name_or_ability != null else ""
	var id: String = Utils.to_id(name_or_ability)

	# Aliases
	if aliases.has(id):
		name = aliases[id]
		id = Utils.to_id(name)


	var battle_abilities = abilities
	var data = battle_abilities.get(id)

	# Si ya existe y es válido
	if typeof(data) == TYPE_DICTIONARY and data.get("exists") != null:
		return data

	# Crear datos por defecto si no existen
	if data == null:
		data = {"exists": false}

	var ability = BattleDexData.Ability.new(id, name, data)
	battle_abilities[id] = ability

	return ability

func get_move(name_or_move) -> BattleDexData.Move:
	# Si ya es un objeto (Move), devolverlo directamente
	if name_or_move != null and typeof(name_or_move) != TYPE_STRING:
		return name_or_move

	var name: String = name_or_move if name_or_move != null else ""
	var id: String = Utils.to_id(name_or_move)

	# Aliases
	if aliases.has(id):
		name = aliases[id]
		id = Utils.to_id(name)


	var movedex = movedex
	var data = movedex.get(id)
	# Si ya existe y es válido
	if typeof(data) == TYPE_DICTIONARY and data.get("exists") != null:
		return data

	# hiddenpower + tipo/poder (ej: hiddenpowerfire70)
	if data == null and id.substr(0, 11) == "hiddenpower" and id.length() > 11:
		var regex = RegEx.new()
		regex.compile("([a-z]*)([0-9]*)")
		var match = regex.search(id.substr(11))

		var hp_type := ""
		var hp_power := ""

		if match:
			hp_type = match.get_string(1)
			hp_power = match.get_string(2)

		var base = movedex.get(hp_type, {})
		data = base.duplicate()
		data["basePower"] = int(hp_power) if hp_power != "" else 60

	# returnXXX
	if data == null and id.substr(0, 6) == "return" and id.length() > 6:
		var base = movedex.get("return", {})
		data = base.duplicate()
		data["basePower"] = int(id.substr(6))

	# frustrationXXX
	if data == null and id.substr(0, 11) == "frustration" and id.length() > 11:
		var base = movedex.get("frustration", {})
		data = base.duplicate()
		data["basePower"] = int(id.substr(11))

	# fallback
	if data == null:
		data = {"exists": false}

	var move = BattleDexData.Move.new(id, name, data)
	movedex[id] = move

	return move


func mod(_gen: String) -> Dex:
	var dex = Dex.new()
	return dex

func sanitize_name(name) -> String:
	if name == null or name == "":
		return ""

	var s: String = str(name)

	s = s.replace("&", "&amp;")
	s = s.replace("<", "&lt;")
	s = s.replace(">", "&gt;")
	s = s.replace('"', "&quot;")

	return s.substr(0, 50)

func get_species(name_or_species):
	# Si ya es un objeto (Species), devolverlo directamente
	if name_or_species != null and typeof(name_or_species) != TYPE_STRING:
		return name_or_species

	var name: String = name_or_species if name_or_species != null else ""
	var id: String = Utils.to_id(name_or_species)
	var formid: String = id

	if alt_forms.has(formid):
		return alt_forms[formid]

	if aliases.has(id):
			name = aliases[id]
			id = Utils.to_id(name)

	var battle_pokedex = pokedex
	var data = battle_pokedex.get(id)

	var species

	# Si ya existe y es válido
	if typeof(data) == TYPE_DICTIONARY and data.get("exists") != null:
		species = data
	else:
		if data == null:
			data = {"exists": false}

		# Tier fallback
		if not data.has("tier") and id.ends_with("totem"):
			var base_id = id.substr(0, id.length() - 5)
			data["tier"] = get_species(base_id).tier

		if not data.has("tier") and data.has("base_species") and Utils.to_id(data["base_species"]) != id:
			data["tier"] = get_species(data["base_species"]).tier

		# NFE cálculo
		var nfe = false
		if id == "dipplin":
			nfe = true
		elif data.has("evos"):
			for evo in data["evos"]:
				var evo_species = get_species(evo)
				if not evo_species.is_nonstandard \
				or evo_species.is_nonstandard == data.get("is_nonstandard") \
				or evo_species.is_nonstandard == "Unobtainable":
					nfe = true
					break

		data["nfe"] = nfe

		species = BattleDexData.Species.new(id, name, data)
		battle_pokedex[id] = species

	# Cosmetic formes
	if species.cosmetic_formes:
		for forme in species.cosmetic_formes:
			if Utils.to_id(forme) == formid:
				var new_species = BattleDexData.Species.new(formid, name, {
					"id": formid,
					"name": forme,
					"forme": forme.substr(species.name.length() + 1),
					"base_forme": "",
					"base_species": species.name,
					"other_formes": null,
				})
				alt_forms[formid] = new_species
				species = new_species
				break

	return species

func for_gen(gen: int) -> Dex:
	var dex = Dex
	return dex
