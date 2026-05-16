extends RefCounted

class FullPokemonSet:
	# Defaults to species name (not including forme), like in games
	var name: String
	var species: String
	# Defaults to no item
	var item: String = ""
	# Defaults to no ability (error in Gen 3+)
	var ability: String = ""
	var moves: Array = []
	# Defaults to no nature (error in Gen 3+)
	var nature: String = ""
	# Defaults to random legal gender, NOT subject to gender ratios
	var gender: String = ""
	# Defaults to flat 252's (200's/0's in Let's Go) (error in gen 3+)
	var evs: Dictionary = {}
	# Defaults to whatever makes sense - flat 31's unless you have Gyro Ball etc
	var ivs: Dictionary = {}
	# Defaults as you'd expect (100 normally, 50 in VGC-likes, 5 in LC)
	var level: int = 100
	# Defaults to no (error if shiny event)
	var shiny: bool = false
	# Defaults to 255 unless you have Frustration, in which case 0
	var happiness: int = 255
	# Defaults to event required ball, otherwise Poké Ball
	var pokeball: String = "poke_ball"
	# Defaults to the type of your Hidden Power in Moves, otherwise Dark
	var hp_type: String = ""
	# Defaults to 10
	var dynamax_level: int = 10
	# Defaults to no (can only be yes for certain Pokemon)
	var gigantamax: bool = false
	# Defaults to the primary type
	var tera_type: String = ""


class PokemonSet:
	var species: String
	var moves: Array = []
	var item: String = ""
	var ability: String = ""
	var nature: String = ""
	var gender: String = ""
	var evs: Dictionary = {}
	var ivs: Dictionary = {}
	var level: int = 100
	var shiny: bool = false
	var happiness: int = 255
	var pokeball: String = "poke_ball"
	var hp_type: String = ""
	var dynamax_level: int = 10
	var gigantamax: bool = false
	var tera_type: String = ""


class Teams:
	func get_iv(ivs: Dictionary, stat: String) -> String:
		if not ivs.has(stat):
			return ""
		return "" if ivs[stat] == 31 else str(ivs[stat])

	func pack(team: Array) -> String:
		if team == null:
			return ""

		var buf := ""

		for set in team:
			if buf != "":
				buf += "]"

			# name
			buf += (set.name if set.has("name") and set.name != "" else set.species)

			# species
			var species_id = pack_name(set.species if set.has("species") else set.name)
			var name_id = pack_name(set.name if set.has("name") else set.species)
			buf += "|" + ("" if name_id == species_id else species_id)

			# item
			buf += "|" + pack_name(set.item if set.has("item") else "")

			# ability
			buf += "|" + pack_name(set.ability if set.has("ability") else "")

			# moves
			var moves := []
			if set.has("moves"):
				for m in set.moves:
					moves.append(pack_name(m))
			buf += "|" + ",".join(moves)

			# nature
			buf += "|" + (set.nature if set.has("nature") else "")

			# evs
			var evs := "|"
			if set.has("evs") and set.evs != null:
				evs = "|" + str(set.evs.get("hp", "")) + "," + str(set.evs.get("atk", "")) + "," + str(set.evs.get("def", "")) + "," + \
					  str(set.evs.get("spa", "")) + "," + str(set.evs.get("spd", "")) + "," + str(set.evs.get("spe", ""))

			buf += "||" if evs == "|,,,,," else evs

			# gender
			buf += "|" + (set.gender if set.has("gender") else "")

			# ivs
			var ivs := "|"
			if set.has("ivs") and set.ivs != null:
				ivs = "|" + get_iv(set.ivs, "hp") + "," + get_iv(set.ivs, "atk") + "," + get_iv(set.ivs, "def") + "," + \
					  get_iv(set.ivs, "spa") + "," + get_iv(set.ivs, "spd") + "," + get_iv(set.ivs, "spe")

			buf += "||" if ivs == "|,,,,," else ivs

			# shiny
			buf += "|" + ("S" if set.has("shiny") and set.shiny else "")

			# level
			buf += "|" + (str(set.level) if set.has("level") and set.level != 100 else "")

			# happiness
			buf += "|" + (str(set.happiness) if set.has("happiness") and set.happiness != 255 else "")

			# extra fields
			if set.has("pokeball") or set.has("hp_type") or set.has("gigantamax") \
				or (set.has("dynamax_level") and set.dynamax_level != 10) or set.has("tera_type"):

				buf += "," + (set.hp_type if set.has("hp_type") else "")
				buf += "," + pack_name(set.pokeball if set.has("pokeball") else "")
				buf += "," + ("G" if set.has("gigantamax") and set.gigantamax else "")
				buf += "," + (str(set.dynamax_level) if set.has("dynamax_level") and set.dynamax_level != 10 else "")
				buf += "," + (set.tera_type if set.has("tera_type") else "")

		return buf

	func pack_name(name) -> String:
		if name == null or name == "":
			return ""

		var s: String = str(name)
		var result := ""

		for i in range(s.length()):
			var c := s[i]
			var code := c.unicode_at(0)

			# keep only A-Z, a-z and 0-9 (no lowercase conversion)
			if (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or (code >= 48 and code <= 57):
				result += c

		return result
