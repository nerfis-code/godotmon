class_name BattlePanel
extends RefCounted

const PS = { "prefs": { "noamin": false } }
var props = { "room": null }
var team: Array

func receive_line(args):
	var room = props.room

	match args[0]:
		"initdone":
			room.battle.seek_turn(INF)
			return

		"request":
			var data = null
			if args.size() > 1 and args[1] != "":
				data = JSON.parse_string(args[1])
			receive_request(data)
			return

		"win", "tie":
			receive_request(null)

		"c", "c:", "chat", "chatmsg", "inactive":
			room.battle.instant_add("|" + "|".join(args))
			return

		"error":
			if args.size() > 1 and args[1].begins_with("[Invalid choice]") and room.request:
				room.choices = BattleChoiceBuilder.new(room.request)
				room.update(null)

	room.battle.add("|" + "|".join(args))

	if PS.prefs.noanim:
		props.room.battle.seek_turn(INF)

func receive_request(request):
	var room = props.room

	if request == null:
		room.request = null
		room.choices = null
		return

	if PS.prefs.autotimer and not room.battle.kicking_inactive and not room.auto_timer_activated:
		send("/timer on")
		room.auto_timer_activated = true

	BattleChoiceBuilder.fix_request(request, room.battle)

	if request.has("side"):
		room.battle.my_pokemon = request.side.pokemon
		room.battle.set_viewpoint(request.side.id)
		room.side = request.side

	if request.has("ally"):
		room.battle.my_ally_pokemon = request.ally.pokemon

	room.request = request
	room.choices = BattleChoiceBuilder.new(request)

	notify_request()
	room.update(null)

func send(what):
	assert(false, "not implemented")

func notify_request():
	pass

class BattleChoiceBuilder:
	var request = null # BattleRequest
	var no_cancel: bool = false
	
	# Completed choices in string form
	var choices: Array[String] = []
	
	# Currently active partial move choice
	var current := {
		"choiceType": "move",
		# if nonzero, show target screen; if zero, show move screen
		"move": 0,
		"targetLoc": 0, # no es parcial si ya se conoce
		"mega": false,
		"megax": false,
		"megay": false,
		"ultra": false,
		"z": false,
		"max": false,
		"tera": false,
	}
	
	var already_switching_in: Array[int] = []
	
	var already_mega: bool = false
	var already_max: bool = false
	var already_z: bool = false
	var already_tera: bool = false
	
	func _init(_request = null):
		request = _request
		
		if request:
			no_cancel = request.noCancel or request.requestType == "wait"
		else:
			no_cancel = false
		
		fill_passes()
	func _to_string() -> String:
		var result = choices.duplicate()

		if current["move"] != 0:
			result.append(string_choice(current))

		var joined = ", ".join(result)
		return joined.replace(", team ", ", ")


	func is_done() -> bool:
		return choices.size() >= request_length()


	func is_empty() -> bool:
		for choice in choices:
			if choice != "pass":
				return false

		if current["move"] != 0:
			return false

		return true


	# Índice del Pokémon actual
	func index() -> int:
		return choices.size()


	# Cuántas decisiones espera el servidor
	func request_length() -> int:
		var req = request

		match req.requestType:
			"move":
				return req.active.size()

			"switch":
				return req.forceSwitch.size()

			"team":
				return req.chosenTeamSize if req.chosenTeamSize != null else 1

			"wait":
				return 0

		return 0
	
	func current_move_request(idx: int = -1):
		if idx == -1:
			idx = index()

		if request.requestType != "move":
			return null

		return request.active[idx]
	
	func add_choice(choice_string: String):
		var choice = null
		
		# parseo con manejo de errores
		var err = null
		choice = parse_choice(choice_string)

		if choice == null:
			return "You do not need to manually choose to pass; the client handles it for you automatically"

		var is_last_choice = choices.size() + 1 >= request_length()

		if choice.choiceType == "move":
			if choice.targetLoc == 0 and request.targetable:
				var choosable_targets = ["normal", "any", "adjacentAlly", "adjacentAllyOrSelf", "adjacentFoe"]
				var move = current_move(choice)
				if move != null and move.target in choosable_targets:
					current = choice
					return null

			var cmr = current_move_request()
			if cmr != null and cmr.has("maybeDisabled") and cmr.maybeDisabled and is_last_choice:
				no_cancel = true

			if choice.mega or choice.megax or choice.megay:
				already_mega = true
			if choice.z:
				already_z = true
			if choice.max:
				already_max = true
			if choice.tera:
				already_tera = true

			current = {
				"choiceType": "move",
				"move": 0,
				"targetLoc": 0,
				"mega": false,
				"megax": false,
				"megay": false,
				"ultra": false,
				"z": false,
				"max": false,
				"tera": false,
			}

		elif choice.choiceType == "switch" or choice.choiceType == "team":
			var cmr = current_move_request()
			if cmr != null and cmr.has("trapped") and cmr.trapped:
				return "You are trapped and cannot switch out"

			if already_switching_in.has(choice.targetPokemon):
				if choice.choiceType == "switch":
					return "You've already chosen to switch that Pokémon in"

				# remover elección
				for i in range(already_switching_in.size()):
					if already_switching_in[i] == choice.targetPokemon:
						already_switching_in.remove_at(i)
						choices.remove_at(i)
						return null

				return "Unexpected bug, please report this"

			if cmr != null and cmr.has("maybeTrapped") and cmr.maybeTrapped and is_last_choice:
				no_cancel = true

			already_switching_in.append(choice.targetPokemon)

		elif choice.choiceType == "testfight":
			if is_last_choice:
				no_cancel = true

		elif choice.choiceType == "shift":
			if index() == 1:
				return "Only Pokémon not already in the center can shift to the center"

		choices.append(string_choice(choice))
		fill_passes()
		return null
	
	func fill_passes():
		match request.request_type:
			"move":
				while (
						(choices.size() < request.active.size() and
						not request.active[choices.size()]) or
						(request.has("side") and 
						request.side.pokemon.size() > choices.size() and 
						request.side.pokemon[choices.size()].get("commanding", false))
					):
					choices.push_back("pass")

			"switch":
				var no_more_switch_choices = no_more_switch_choices()
				while (choices.size() < request.forceSwitch.size()):
					if not request.forceSwitch[choices.size()] or no_more_switch_choices:
						choices.push_back("pass")
					else:
						return
			
	func current_move(choice = null, idx: int = -1):
		if choice == null:
			choice = current
		if idx == -1:
			idx = index()

		var move_index = choice["move"] - 1

		var move_list = current_move_list(idx, choice)
		if move_list == null:
			return null

		if move_index < 0 or move_index >= move_list.size():
			return null

		return move_list[move_index]

	func current_move_list(idx: int = -1, current_choice = null):
		if idx == -1:
			idx = index()
		if current_choice == null:
			current_choice = current

		var move_request = current_move_request(idx)
		if move_request == null:
			return null

		# max moves
		if current_choice.has("max") and current_choice["max"] \
		or (move_request.has("maxMoves") and not move_request.get("canDynamax", true)):
			return move_request.get("maxMoves", null)

		# z moves
		if current_choice.has("z") and current_choice["z"]:
			return move_request.get("zMoves", null)

		# normales
		return move_request.get("moves", null)
		
	func no_more_switch_choices() -> bool:
		if request.requestType != "switch":
			return false

		for i in range(request_length(), request.side.pokemon.size()):
			var pokemon = request.side.pokemon[i]

			if (not pokemon.fainted and not already_switching_in.has(i + 1)):
				return false

		return true
		
	func parse_choice(choice: String, idx: int = -1):
		if idx == -1:
			idx = choices.size()

		var request = self.request

		if request["requestType"] == "wait":
			push_error("It's not your turn to choose anything")
			return null

		if choice == "shift" or choice == "testfight":
			if request["requestType"] != "move":
				push_error("You must switch in a Pokémon, not move.")
				return null
			return { "choiceType": choice }

		if choice.begins_with("move "):
			if request["requestType"] != "move":
				push_error("You must switch in a Pokémon, not move.")
				return null

			var move_request = request["active"][idx]
			choice = choice.substr(5).strip_edges()

			var current = {
				"choiceType": "move",
				"move": 0,
				"targetLoc": 0,
				"mega": false,
				"megax": false,
				"megay": false,
				"ultra": false,
				"z": false,
				"max": false,
				"tera": false,
			}

			while true:
				if choice.match(".*\\s[\\-\\+]?[1-3]$") and Utils.to_id(choice) != "conversion2":
					if current["targetLoc"] != 0:
						push_error("Move choice has multiple targets")
						return null
					current["targetLoc"] = int(choice.substr(choice.length() - 2))
					choice = choice.substr(0, choice.length() - 2).strip_edges()

				elif choice.ends_with(" mega"):
					current["mega"] = true
					choice = choice.substr(0, choice.length() - 5)

				elif choice.ends_with(" megax"):
					current["megax"] = true
					choice = choice.substr(0, choice.length() - 6)

				elif choice.ends_with(" megay"):
					current["megay"] = true
					choice = choice.substr(0, choice.length() - 6)

				elif choice.ends_with(" zmove"):
					current["z"] = true
					choice = choice.substr(0, choice.length() - 6)

				elif choice.ends_with(" ultra"):
					current["ultra"] = true
					choice = choice.substr(0, choice.length() - 6)

				elif choice.ends_with(" dynamax"):
					current["max"] = true
					choice = choice.substr(0, choice.length() - 8)

				elif choice.ends_with(" max"):
					current["max"] = true
					choice = choice.substr(0, choice.length() - 4)

				elif choice.ends_with(" terastallize"):
					current["tera"] = true
					choice = choice.substr(0, choice.length() - 13)

				elif choice.ends_with(" terastal"):
					current["tera"] = true
					choice = choice.substr(0, choice.length() - 9)

				else:
					break

			if choice.is_valid_int():
				current["move"] = int(choice)
			else:
				var moveid = Utils.to_id(choice)
				if moveid.begins_with("hiddenpower"):
					moveid = "hiddenpower"

				for i in range(move_request["moves"].size()):
					var m = move_request["moves"][i]
					if moveid == m["id"]:
						if m.get("disabled", false):
							push_error("Move \"%s\" is disabled" % m["name"])
							return null
						current["move"] = i + 1
						break

				if current["move"] == 0 and move_request.has("zMoves"):
					for i in range(move_request["zMoves"].size()):
						var m = move_request["zMoves"][i]
						if m == null:
							continue
						if moveid == m["id"]:
							current["move"] = i + 1
							current["z"] = true
							break

				if current["move"] == 0 and move_request.has("maxMoves"):
					for i in range(move_request["maxMoves"].size()):
						var m = move_request["maxMoves"][i]
						if moveid == m["id"]:
							if m.get("disabled", false):
								push_error("Move \"%s\" is disabled" % m["name"])
								return null
							current["move"] = i + 1
							current["max"] = true
							break

			if current["max"] and not move_request.get("canDynamax", true):
				current["max"] = false

			var move = current_move(current, idx)
			if move == null or move.get("disabled", false):
				push_error("Move is disabled")
				return null

			return current

		if choice.begins_with("switch ") or choice.begins_with("team "):
			var is_team = choice.begins_with("team ")
			choice = choice.substr(5 if is_team else 7)

			var is_preview = request["requestType"] == "team"

			var current = {
				"choiceType": "team" if is_preview else "switch",
				"targetPokemon": 0
			}

			if choice == "notMine":
				push_error("You cannot decide for your partner!")
				return null

			if choice.is_valid_int():
				current["targetPokemon"] = int(choice)
			else:
				var choiceid = Utils.to_id(choice)
				var found = 0
				var match_level = 0

				for i in range(request["side"]["pokemon"].size()):
					var p = request["side"]["pokemon"][i]
					var level = 0

					if choice == p["name"]:
						level = 10
					elif choice.to_lower() == p["name"].to_lower():
						level = 9
					elif choiceid == Utils.to_id(p["name"]):
						level = 8
					elif choiceid == Utils.to_id(p["speciesForme"]):
						level = 7

					if level > match_level:
						found = i + 1
						match_level = level

				if found == 0:
					push_error("Couldn't find Pokémon \"%s\"" % choice)
					return null

				current["targetPokemon"] = found

			if not is_preview and current["targetPokemon"] - 1 < request_length():
				push_error("That Pokémon is already in battle!")
				return null

			var target = request["side"]["pokemon"][current["targetPokemon"] - 1]
			if target == null:
				push_error("Invalid Pokémon")
				return null

			if target.get("fainted", false):
				push_error("%s is fainted and cannot battle!" % target["name"])
				return null

			return current

		if choice == "pass":
			return null

		push_error("Unrecognized choice \"%s\"" % choice)
		return null
		
	func string_choice(choice):
		if choice == null:
			return "pass"
		match choice.choiceType:
			"move":
				var target = ""
				if choice.targetLoc != 0:
					target = " " + ( "+" if choice.targetLoc > 0 else "" ) + str(choice.targetLoc)
				return "move %d%s%s" % [choice.move, move_special(choice), target]
			"switch", "team":
				return "%s %d" % [choice.choiceType, choice.targetPokemon]
			"shift", "testfight":
				return choice.choiceType

	func move_special(choice):
		return ( " max" if choice.max else "" ) + \
			( " mega" if choice.mega else "" ) + \
			( " megax" if choice.megax else "" ) + \
			( " megay" if choice.megay else "" ) + \
			( " ultra" if choice.ultra else "" ) + \
			( " zmove" if choice.z else "" ) + \
			( " terastallize" if choice.tera else "" )
			
	static func fix_request(request, battle):
		if not request.has("requestType"):
			request.requestType = "move"
			if request.get("forceSwitch"):
				request.requestType = "switch"
			elif request.get("teamPreview"):
				request.requestType = "team"
			elif request.get("wait"):
				request.requestType = "wait"

		if request.requestType == "wait":
			request.noCancel = true

		if request.has("side"):
			for server_pokemon in request.side.pokemon:
				battle.parseDetails(server_pokemon.ident.substr(4), server_pokemon.ident, server_pokemon.details, server_pokemon)
				battle.parseHealth(server_pokemon.condition, server_pokemon)

		if request.has("ally"):
			for server_pokemon in request.ally.pokemon:
				battle.parseDetails(server_pokemon.ident.substr(4), server_pokemon.ident, server_pokemon.details, server_pokemon)
				battle.parseHealth(server_pokemon.condition, server_pokemon)

		if request.requestType == "team" and not request.get("chosenTeamSize"):
			request.chosenTeamSize = 1
			if battle.gameType == "doubles":
				request.chosenTeamSize = 2
			if battle.gameType == "triples" or battle.gameType == "rotation":
				request.chosenTeamSize = 3

			for switchable in request.side.pokemon:
				if Utils.to_id(switchable.baseAbility) == "illusion":
					request.chosenTeamSize = request.side.pokemon.size()

			if request.get("maxChosenTeamSize"):
				request.chosenTeamSize = request.maxChosenTeamSize

			if battle.teamPreviewCount:
				var chosen_team_size = battle.teamPreviewCount
				if chosen_team_size > 0 and chosen_team_size <= request.side.pokemon.size():
					request.chosenTeamSize = chosen_team_size

		request.targetable = request.get("targetable", false) or battle.mySide.active.size() > 1

		if request.has("active"):
			var new_active = []
			for i in range(request.active.size()):
				if request.side.pokemon[i].fainted:
					new_active.append(null)
				else:
					new_active.append(request.active[i])
			request.active = new_active

			for active in request.active:
				if active == null:
					continue

				for move in active.moves:
					if move.get("move"):
						move.name = move.move
					move.id = Utils.to_id(move.name)

				if active.get("maxMoves"):
					if active.maxMoves.get("maxMoves"):
						active.gigantamax = active.maxMoves.gigantamax
						active.maxMoves = active.maxMoves.maxMoves

					for move in active.maxMoves:
						if move.get("move"):
							move.name = Dex.moves.get(move.move).name
						move.id = Utils.to_id(move.name)

				if active.get("canZMove"):
					active.zMoves = active.canZMove
					for move in active.zMoves:
						if move == null:
							continue
						if move.get("move"):
							move.name = move.move
						move.id = Utils.to_id(move.name)
  
class BattleRoom:

	var class_type: String = "battle"

	# equivalentes a declare
	var pm_target = null
	var challenge_menu_open: bool = false
	var challenging_format = null
	var challenged_format = null

	# propiedades principales
	var battle: Battle = null

	# null si es espectador
	var side = null # BattleRequestSideInfo
	var request = null # BattleRequest
	var choices = null # BattleChoiceBuilder
	var auto_timer_activated = null # bool
