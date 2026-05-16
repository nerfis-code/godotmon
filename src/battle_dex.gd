extends Node

const BattleDexData = preload("uid://d1mlt2fddq0e8")
var battle_items = preload("uid://cs5tenx7noy6f").AB
var BattleMovedex = {}

func _ready():
	var json = FileAccess.open("res://src/moves.json", FileAccess.READ).get_as_text()
	BattleMovedex = JSON.parse_string(json)

func get_item(name_or_item) -> BattleDexData.Item:
	# Si ya es un objeto (Item), devolverlo directamente
	if name_or_item != null and typeof(name_or_item) != TYPE_STRING:
		return name_or_item

	var name: String = name_or_item if name_or_item != null else ""
	var id: String = Utils.to_id(name_or_item)

	# Aliases
	if Engine.has_singleton("BattleAliases"):
		var aliases = Engine.get_singleton("BattleAliases")
		if aliases.has(id):
			name = aliases[id]
			id = Utils.to_id(name)

	var data = battle_items.get(id)

	# Si ya existe y es válido, devolverlo
	if typeof(data) == TYPE_DICTIONARY and data.get("exists") != null:
		return data

	# Crear datos por defecto si no existen
	if data == null:
		data = { "exists": false }

	var item = BattleDexData.Item.new(id, name, data)
	#battle_items[id] = item

	return item


func get_effect(name) -> Variant:
	name = ("" if name == null else str(name)).strip_edges()

	if name.substr(0, 5) == "item:":
		return Dex.items.get(name.substr(5).strip_edges())
	elif name.substr(0, 8) == "ability:":
		return Dex.abilities.get(name.substr(8).strip_edges())
	elif name.substr(0, 5) == "move:":
		return Dex.moves.get(name.substr(5).strip_edges())

	var id: String = Utils.to_id(name)
	return BattleDexData.PureEffect.new(id, name)

func get_ability(ability_id: String) -> Dictionary:
	return { }

func get_move(name_or_move) -> BattleDexData.Move:
	# Si ya es un objeto (Move), devolverlo directamente
	if name_or_move != null and typeof(name_or_move) != TYPE_STRING:
		return name_or_move

	var name: String = name_or_move if name_or_move != null else ""
	var id: String = Utils.to_id(name_or_move)

	# Aliases
	if Engine.has_singleton("BattleAliases"):
		var aliases = Engine.get_singleton("BattleAliases")
		if aliases.has(id):
			name = aliases[id]
			id = Utils.to_id(name)


	var movedex = BattleMovedex
	var data = movedex.get(id)
	print("move data for id '%s': %s" % [id, str(data)])
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

func sanitize_name(name: String) -> String:
		return name.strip_edges().to_lower()
