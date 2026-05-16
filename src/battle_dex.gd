extends Node

const BattleDexData = preload("uid://d1mlt2fddq0e8")
var battle_items = preload("uid://cs5tenx7noy6f").AB

var items = {
	"foo": func(name_or_item):
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
}


func get_effect(effect_id: String) -> Dictionary:
	return { }


func get_ability(ability_id: String) -> Dictionary:
	return { }


func get_item(item_id: String) -> Dictionary:
	return { }


func get_move(move_id: String) -> Dictionary:
	return { }


func mod(gen: String) -> Dex:
	var dex = Dex.new()
	return dex

func sanitize_name(name: String) -> String:
		return name.strip_edges().to_lower()
