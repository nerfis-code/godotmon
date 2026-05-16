class_name Battle
extends RefCounted

var scene: BattleScene
var viewpoint_switched: bool = false

var step_queue: Array = []
var preempt_step_queue: Array = []
var wait_for_animations
var current_step: int = 0
var seeking = null

var active_move_is_spread = null

var subscription: Callable

var mute: bool = false
var message_fade_time: int = 300
var message_shown_time: int = 1
var turns_since_moved: int = 0

var turn: int = -1
var at_queue_end: bool = false
var started: bool = false
var ended: bool = false
var is_replay: bool = false
var uses_upkeep: bool = false
var weather: String = ""
var pseudo_weather: Array = []
var weather_time_left: int = 0
var weather_min_time_left: int = 0

var my_side: BattleSide
var near_side: BattleSide
var far_side: BattleSide
var p1: BattleSide
var p2: BattleSide
var p3: BattleSide
var p4: BattleSide
var pokemon_controlled: int = 0
var sides: Array[BattleSide] = []
var my_pokemon: Array = []
var my_ally_pokemon: Array = []
var last_move: String = ""

var gen: int = 8
var dex = Dex
var team_preview_count: int = 0
var species_clause: bool = false
var tier: String = ""
var game_type: String = "singles"
var compat_mode: bool = true
var rated = false
var rules: Dictionary = {}
var is_blitz: bool = false
var report_exact_hp: bool = false
var end_last_turn_pending: bool = false
var total_time_left: int = 0
var grace_time_left: int = 0
var kicking_inactive = false

var id: String = ""
var room_id: String = ""
var hardcore_mode: bool = false
var ignore_nicks: bool = false
var ignore_opponent: bool = false
var ignore_spects: bool = false
var debug: bool = false
var join_buttons: bool = false
var autoresize: bool = false
var paused: bool = false

func _init(options: Dictionary = {}):
	id = options.get("id", "")
	scene = BattleScene.new()

	paused = options.get("paused", false)
	started = not paused
	debug = options.get("debug", false)
	
	var log_data = options.get("log", [])
	if typeof(log_data) == TYPE_STRING:
		step_queue = log_data.split("\n")
	else:
		step_queue = log_data
		
	if options.has("subscription"):
		subscription = options["subscription"]
		
	autoresize = options.get("autoresize", false)

	p1 = BattleSide.new(self , 0)
	p2 = BattleSide.new(self , 1)
	sides = [p1, p2]
	p2.foe = p1
	p1.foe = p2
	my_side = p1
	near_side = p1
	far_side = p2

	reset_step()

func subscribe(listener: Callable):
	subscription = listener

func remove_pseudo_weather(_weather: String):
	for i in range(pseudo_weather.size()):
		if pseudo_weather[i][0] == _weather:
			pseudo_weather.remove_at(i)
			if scene and scene.has_method("update_weather"):
				scene.update_weather()
			return

func add_pseudo_weather(_weather: String, min_time_left: int, time_left: int):
	pseudo_weather.append([_weather, min_time_left, time_left])
	if scene and scene.has_method("update_weather"):
		scene.update_weather()

func has_pseudo_weather(_weather: String) -> bool:
	for pw in pseudo_weather:
		if _weather == pw[0]:
			return true
	return false

func get_all_active() -> Array[Pokemon]:
	var pokemon_list: Array[Pokemon] = []
	for i in range(2):
		var side = sides[i]
		for active in side.active:
			if active and not active.fainted:
				pokemon_list.append(active)
	return pokemon_list

func reset():
	paused = true
	scene.pause()
	reset_step()
	if subscription.is_valid():
		subscription.call("paused")

func reset_step():
	turn = -1
	started = not paused
	ended = false
	at_queue_end = false
	weather = ""
	weather_time_left = 0
	weather_min_time_left = 0
	pseudo_weather.clear()
	last_move = ""

	for side in sides:
		if side: side.reset()
	my_pokemon = []
	my_ally_pokemon = []

	scene.reset()

	active_move_is_spread = null
	current_step = 0
	reset_turns_since_moved()
	next_step()

func destroy():
	scene.destroy()
	for i in range(sides.size()):
		if sides[i]:
			sides[i].destroy()
		sides[i] = null
	my_side = null
	near_side = null
	far_side = null
	p1 = null
	p2 = null
	p3 = null
	p4 = null

func add_log(args: Array, kwargs: Dictionary = {}, preempt: bool = false):
	scene.log.add(args, kwargs, preempt)

func start():
	add_log(["start"])
	reset_turns_since_moved()

func winner(_winner: String = ""):
	add_log(["win", _winner])
	ended = true
	if subscription.is_valid():
		subscription.call("ended")

func premature_end():
	add_log(["message", "This replay ends here."])
	ended = true
	if subscription.is_valid():
		subscription.call("ended")

func end_last_turn():
	if end_last_turn_pending:
		end_last_turn_pending = false
		if scene and scene.has_method("update_statbars"):
			scene.update_statbars()

func set_turn(turn_num: int):
	if turn_num == turn + 1:
		end_last_turn_pending = true
	if turn and not uses_upkeep:
		update_turn_counters()
	turn = turn_num
	started = true

	if seeking == null:
		turns_since_moved += 1

	if scene and scene.has_method("increment_turn"):
		scene.increment_turn()

	if seeking != null:
		if turn_num >= seeking:
			pass # stopSeeking()
	else:
		if subscription.is_valid():
			subscription.call("turn")

func reset_turns_since_moved():
	turns_since_moved = 0
	scene.update_acceleration()
		

func update_turn_counters():
	for p_weather in pseudo_weather:
		if p_weather[1] > 0: p_weather[1] -= 1
		if p_weather[2] > 0: p_weather[2] -= 1
	for side in sides:
		for id in side.side_conditions:
			var cond = side.side_conditions[id]
			if cond[2] > 0: cond[2] -= 1
			if cond[3] > 0: cond[3] -= 1
	var actives = []
	if near_side: actives.append_array(near_side.active)
	if far_side: actives.append_array(far_side.active)
	for poke in actives:
		if poke:
			if poke.status == StatusName.TOX:
				poke.statusData["toxicTurns"] += 1
			poke.clear_turnstatuses()
	if scene and scene.has_method("update_weather"):
		scene.update_weather()

func run_major(args: Array, kwargs: Dictionary = {}, preempt: bool = false):    
	match args[0]:
		"start":
			near_side.active[0] = null
			far_side.active[0] = null
			scene.reset_sides()
			start()
		"player":
			var side = get_side(args[1])

			side.set_name(args[2])

			if args.size() > 3 and args[3]:
				side.set_avatar(args[3])

			if args.size() > 4 and args[4]:
				side.rating = args[4]

			if join_buttons:
				scene.hide_join_buttons()

			add_log(args)
			scene.update_sidebar(side)
		"switch", "drag", "replace":
			end_last_turn()

			var poke = get_switched_pokemon(args[1], args[2])
			var slot = poke.slot

			poke.health_parse(args[3])
			poke.remove_volatile("itemremoved")

			var tera_match = RegEx.new()
			tera_match.compile("tera:([a-z]+)$")
			var result = tera_match.search(args[2])
			poke.terastallized = result.get_string(1) if result else ""

			if args[0] == "switch":
				if poke.side.active[slot]:
					poke.side.switch_out(poke.side.active[slot], kwargs)
				poke.side.switch_in(poke, kwargs)

			elif args[0] == "replace":
				poke.side.replace(poke)

			else:
				poke.side.drag_in(poke)

			scene.update_weather()
			add_log(args, kwargs)
		"teamsize":
			var side = get_side(args[1])
			side.total_pokemon = int(args[2])
			scene.update_sidebar(side)
		"gametype":
			game_type = args[1]
			compat_mode = false

			match args[1]:
				"multi", "freeforall":
					pokemon_controlled = 1

					if not p3:
						p3 = BattleSide.new(self, 2)
					if not p4:
						p4 = BattleSide.new(self, 3)

					p3.foe = p2
					p4.foe = p1

					if args[1] == "multi":
						p4.ally = p2
						p3.ally = p1
						p1.ally = p3
						p2.ally = p4

					p3.is_far = p1.is_far
					p4.is_far = p2.is_far

					sides = [p1, p2, p3, p4]

					p1.active = [null, null]
					p3.active = p1.active

					p2.active = [null, null]
					p4.active = p2.active

				"doubles":
					near_side.active = [null, null]
					far_side.active = [null, null]

				"triples", "rotation":
					near_side.active = [null, null, null]
					far_side.active = [null, null, null]

				_:
					for side in sides:
						side.active = [null]

			if not pokemon_controlled:
				pokemon_controlled = near_side.active.size()

			scene.update_gen()
			scene.reset_sides()
		"turn":
			set_turn(int(args[1]))
			add_log(args, kwargs)
		"move":
			end_last_turn()
			reset_turns_since_moved()

			var poke = get_pokemon(args[1])
			var move := Dex.get_move(args[2])

			if check_active(poke):
				return

			var poke2 = get_pokemon(args[3])

			scene.before_move(poke)
			use_move(poke, move, poke2, kwargs)
			animate_move(poke, move, poke2, kwargs)
			scene.after_move(poke)

			add_log(args, kwargs)
		"fieldhtml":
			scene.set_frame_html(args[1])
		"controlshtml":
			scene.set_controls_html(args[1])
		_:
			pass

func change_weather(weather_name: String, poke: Pokemon = null, is_ipkeep: bool = false, ability: Dictionary = {}):
	var w = weather_name.to_lower().replace(" ", "")
	if not w or w == "none":
		w = ""
	
	if is_ipkeep:
		if weather and weather_time_left > 0:
			weather_time_left -= 1
			if weather_min_time_left > 0:
				weather_min_time_left -= 1
		if seeking == null:
			if scene and scene.has_method("upkeep_weather"):
				scene.upkeep_weather()
		return
	
	if w:
		var is_extreme_weather = (w == "deltastream" or w == "desolateland" or w == "primordialsea")
		if poke:
			if ability.size() > 0:
				activate_ability(poke, ability.get("name", ""))
			weather_time_left = 0 if (gen <= 5 or is_extreme_weather) else 8
			weather_min_time_left = 0 if (gen <= 5 or is_extreme_weather) else 5
		elif is_extreme_weather:
			weather_time_left = 0
			weather_min_time_left = 0
		else:
			weather_time_left = 5 if gen <= 3 else 8
			weather_min_time_left = 0 if gen <= 3 else 5
	
	weather = w
	if scene and scene.has_method("update_weather"):
		scene.update_weather()

func swap_side_conditions():
	var conds = [
		"mist", "lightscreen", "reflect", "spikes", "safeguard", "tailwind", "toxicspikes", "stealthrock", "waterpledge", "firepledge", "grasspledge", "stickyweb", "auroraveil", "gmaxsteelsurge", "gmaxcannonade", "gmaxvinelash", "gmaxwildfire"
	]
	if game_type == "freeforall":
		var sds = [sides[0], sides.size() > 3 and sides[3] or null, sides.size() > 1 and sides[1] or null, sides.size() > 2 and sides[2] or null]
		var temp = {0: {}, 1: {}, 2: {}, 3: {}}
		for side in sds:
			if not side: continue
			for id in side.side_conditions.keys():
				if not conds.has(id): continue
				temp[side.n][id] = side.side_conditions[id]
				side.remove_side_condition(id)
		for i in range(4):
			var source_side = sds[i]
			if not source_side: continue
			var source_side_conditions = temp.get(source_side.n, {})
			var target_side = sds[(i + 1) % 4]
			if not target_side: continue
			for id in source_side_conditions.keys():
				target_side.side_conditions[id] = source_side_conditions[id]
				if scene and scene.has_method("add_side_condition"):
					scene.add_side_condition(target_side.n, id)
		return
	
	var side1 = sides[0]
	var side2 = sides[1]
	for id in conds:
		if side1.side_conditions.has(id) and side2.side_conditions.has(id):
			var t = side1.side_conditions[id]
			side1.side_conditions[id] = side2.side_conditions[id]
			side2.side_conditions[id] = t
			if scene and scene.has_method("add_side_condition"):
				scene.add_side_condition(side1.n, id)
				scene.add_side_condition(side2.n, id)
		elif side1.side_conditions.has(id) and not side2.side_conditions.has(id):
			side2.side_conditions[id] = side1.side_conditions[id]
			if scene and scene.has_method("add_side_condition"):
				scene.add_side_condition(side2.n, id)
			side1.remove_side_condition(id)
		elif side2.side_conditions.has(id) and not side1.side_conditions.has(id):
			side1.side_conditions[id] = side2.side_conditions[id]
			if scene and scene.has_method("add_side_condition"):
				scene.add_side_condition(side1.n, id)
			side2.remove_side_condition(id)

func use_move(pokemon: Pokemon, move: Variant, target: Pokemon, kwargs: Dictionary):
	var fromeffect = dex.get_effect(kwargs.get("from", "")) if dex and dex.has_method("get_effect") else {"id": kwargs.get("from", ""), "name": kwargs.get("from", "")}
	activate_ability(pokemon, fromeffect)
	pokemon.clear_movestatuses()
	if move.get("id") == "focuspunch":
		pokemon.remove_turnstatus("focuspunch")
	if scene and scene.has_method("update_statbar"):
		scene.update_statbar(pokemon)
	if fromeffect.get("id") == "sleeptalk":
		pokemon.remember_move(move.get("name", ""), 0)
		
	var caller_move_for_pressure = null
	if fromeffect.get("id") and String(kwargs.get("from", "")).begins_with("move:"):
		caller_move_for_pressure = fromeffect
		
	if not fromeffect.get("id") or caller_move_for_pressure or fromeffect.get("id") == "pursuit":
		var move_name = move.get("name", "")
		if not caller_move_for_pressure:
			if move.get("isZ"):
				pokemon.item = move.get("isZ")
				var item = dex.get_item(move.get("isZ")) if dex and "items" in dex else {}
				if item and item.get("zMoveFrom"):
					move_name = item.get("zMoveFrom")
			elif move_name.begins_with("Z-"):
				move_name = move_name.substr(2)
				move = dex.get_move(move_name) if dex and "moves" in dex else {}
				
		var pp = 1
		if ability_active("Pressure") and move.get("id") != "stickyweb":
			var foe_targets = []
			var move_target = move.get("pressureTarget", "")
			
			if not target and game_type == "singles" and not move_target in ["self", "allies", "allySide", "adjacentAlly", "adjacentAllyOrSelf", "allyTeam"]:
				if pokemon.side and pokemon.side.foe and pokemon.side.foe.active.size() > 0:
					foe_targets.append(pokemon.side.foe.active[0])
			elif move_target in ["all", "allAdjacent", "allAdjacentFoes", "foeSide"]:
				for active in get_all_active():
					if active == pokemon: continue
					if gen <= 4 or (active.side != pokemon.side and active.side.ally != pokemon.side):
						foe_targets.append(active)
			elif target and target.side != pokemon.side:
				foe_targets.append(target)
				
			for foe in foe_targets:
				if foe and not foe.fainted and foe.effective_ability() == "Pressure":
					pp += 1
					
		if not caller_move_for_pressure:
			pokemon.remember_move(move_name, pp)
		else:
			pokemon.remember_move(caller_move_for_pressure.get("name", ""), pp - 1)
			
	pokemon.last_move = move.get("id", "")
	last_move = move.get("id", "")
	if last_move in ["wish", "healingwish"]:
		if pokemon.side:
			pokemon.side.wisher = pokemon

func ability_active(abilities) -> bool:
	if typeof(abilities) == TYPE_STRING:
		abilities = [abilities]
	var lower_abilities = []
	for a in abilities:
		lower_abilities.append(a.to_lower().replace(" ", ""))
		
	for active in get_all_active():
		var effect_ab = active.effective_ability() if active.has_method("effective_ability") else active.ability
		if lower_abilities.has(effect_ab.to_lower().replace(" ", "")):
			return true
	return false

func animate_move(pokemon: Pokemon, move: Variant, target: Pokemon, kwargs: Dictionary):
	active_move_is_spread = kwargs.get("spread", null)
	if seeking != null or kwargs.get("still"): return
	
	if not target:
		if pokemon.side and pokemon.side.foe and pokemon.side.foe.active.size() > 0:
			target = pokemon.side.foe.active[0]
	if not target:
		if pokemon.side and pokemon.side.foe:
			target = pokemon.side.foe.missed_pokemon
	if kwargs.get("miss") and target and target.side:
		target = target.side.missed_pokemon
	if kwargs.get("notarget"):
		return
		
	if kwargs.get("prepare") or kwargs.get("anim") == "prepare":
		if scene and scene.has_method("run_prepare_anim"):
			scene.run_prepare_anim(move.get("id"), pokemon, target)
		return
		
	var used_move = move
	if kwargs.get("anim"):
		used_move = dex.get_move(kwargs.get("anim")) if dex and "moves" in dex else {"id": kwargs.get("anim")}
		
	if not kwargs.get("spread"):
		if scene and scene.has_method("run_move_anim"):
			scene.run_move_anim(used_move.get("id"), [pokemon, target])
		return
		
	var targets = [pokemon]
	var spread = kwargs.get("spread", "")
	if spread == ".":
		if target and target.side:
			targets.append(target.side.missed_pokemon)
	else:
		for hit_target in spread.split(","):
			var cur_target = get_pokemon(hit_target + ": ?")
			if not cur_target:
				add_log(["error", "Invalid spread move target: " + hit_target])
				continue
			targets.append(cur_target)
			
	if scene and scene.has_method("run_move_anim"):
		scene.run_move_anim(used_move.get("id"), targets)

func cant_use_move(pokemon: Pokemon, effect: Dictionary, move: Dictionary, kwargs: Dictionary):
	pokemon.clear_movestatuses()
	if scene and scene.has_method("update_statbar"):
		scene.update_statbar(pokemon)
	if scene and scene.has_method("run_status_anim"):
		scene.run_status_anim(effect.get("id", ""), [pokemon])
		
	activate_ability(pokemon, effect)
	if move.get("id"):
		pokemon.remember_move(move.get("name", ""), 0)
		
	match effect.get("id", ""):
		"par":
			if scene and scene.has_method("result_anim"): scene.result_anim(pokemon, "Paralyzed", "par")
		"frz":
			if scene and scene.has_method("result_anim"): scene.result_anim(pokemon, "Frozen", "frz")
		"slp":
			if scene and scene.has_method("result_anim"): scene.result_anim(pokemon, "Asleep", "slp")
			pokemon.status_data["sleepTurns"] += 1
		"truant":
			if scene and scene.has_method("result_anim"): scene.result_anim(pokemon, "Loafing around", "neutral")
		"recharge":
			if scene and scene.has_method("run_other_anim"): scene.run_other_anim("selfstatus", [pokemon])
			if scene and scene.has_method("result_anim"): scene.result_anim(pokemon, "Must recharge", "neutral")
		"focuspunch":
			if scene and scene.has_method("result_anim"): scene.result_anim(pokemon, "Lost focus", "neutral")
			pokemon.remove_turnstatus("focuspunch")
		"shelltrap":
			if scene and scene.has_method("result_anim"): scene.result_anim(pokemon, "Trap failed", "neutral")
			pokemon.remove_turnstatus("shelltrap")
		"flinch":
			if scene and scene.has_method("result_anim"): scene.result_anim(pokemon, "Flinched", "neutral")
			pokemon.remove_turnstatus("focuspunch")
		"attract":
			if scene and scene.has_method("result_anim"): scene.result_anim(pokemon, "Immobilized", "neutral")
			
	if scene and scene.has_method("anim_reset"):
		scene.anim_reset(pokemon)

func activate_ability(pokemon: Pokemon, effect_or_name, is_not_base: bool = false):
	if not pokemon or not effect_or_name: return
	var effect_name = effect_or_name
	if typeof(effect_or_name) == TYPE_DICTIONARY:
		if effect_or_name.get("effectType") != "Ability": return
		effect_name = effect_or_name.get("name", "")
		
	if scene and scene.has_method("ability_activate_anim"):
		scene.ability_activate_anim(pokemon, effect_name)
	pokemon.remember_ability(effect_name, is_not_base)

func parse_pokemon_id(pokemonid: String) -> Dictionary:
	var name = pokemonid

	var siden = -1
	var slot = -1 # si hay un slot explícito para este pokemon

	var regex_basic = RegEx.new()
	regex_basic.compile("^p[1-9]($|: )")

	var regex_with_slot = RegEx.new()
	regex_with_slot.compile("^p[1-9][a-f]: ")

	if regex_basic.search(name):
		siden = int(name[1]) - 1
		name = name.substr(4)

	elif regex_with_slot.search(name):
		var slot_chart = {
			"a": 0, "b": 1, "c": 2,
			"d": 3, "e": 4, "f": 5
		}

		siden = int(name[1]) - 1
		slot = slot_chart.get(name[2], -1)
		name = name.substr(5)
		pokemonid = "p%d: %s" % [siden + 1, name]

	return {
		"name": name,
		"siden": siden,
		"slot": slot,
		"pokemonid": pokemonid
	}

func get_switched_pokemon(pokemonid: String, details: String) -> Pokemon:
	if pokemonid == "??":
		push_error("pokemonid not passed")
		return null

	var parsed = parse_pokemon_id(pokemonid)
	var name = parsed.name
	var siden = parsed.siden
	var slot = parsed.slot
	pokemonid = parsed.pokemonid

	var searchid = "%s|%s" % [pokemonid, details]
	var side = sides[siden]

	# search inactive revealed pokemon
	for i in range(side.pokemon.size()):
		var pokemon = side.pokemon[i]

		if pokemon.fainted:
			continue

		# already active, can't be switching in
		if pokemon in side.active:
			continue

		# just switched out, can't be switching in
		if pokemon == side.last_pokemon and not side.active[slot]:
			continue

		if pokemon.searchid == searchid:
			# exact match
			if slot >= 0:
				pokemon.slot = slot
			return pokemon

		if not pokemon.searchid and pokemon.check_details(details):
			# switch-in matches Team Preview entry
			pokemon = side.add_pokemon(name, pokemonid, details, i)
			if slot >= 0:
				pokemon.slot = slot
			return pokemon

	# pokemon not found, create a new pokemon object for it
	var pokemon = side.add_pokemon(name, pokemonid, details)
	if slot >= 0:
		pokemon.slot = slot

	return pokemon

func get_pokemon(pokemonid: String, fainted_only: bool = false):
	if not pokemonid or pokemonid == "??" or pokemonid == "null" or pokemonid == "false":
		return null

	var parsed = parse_pokemon_id(pokemonid)
	var siden = parsed.siden
	var slot = parsed.slot
	pokemonid = parsed.pokemonid

	var is_inactive = slot < 0
	var side = sides[siden]

	if not is_inactive and side.active[slot]:
		return side.active[slot]

	for pokemon in side.pokemon:
		if is_inactive and not compat_mode and pokemon in side.active:
			continue

		if fainted_only and pokemon.hp:
			continue

		if pokemon.ident == pokemonid:
			if slot >= 0:
				pokemon.slot = slot
			return pokemon

	return null

func get_side(sidename: String) -> BattleSide:
	if sidename == "p1" or sidename.begins_with("p1:"): return p1
	if sidename == "p2" or sidename.begins_with("p2:"): return p2
	if (sidename == "p3" or sidename.begins_with("p3:")) and p3: return p3
	if (sidename == "p4" or sidename.begins_with("p4:")) and p4: return p4
	if near_side and near_side.id == sidename: return near_side
	if far_side and far_side.id == sidename: return far_side
	if near_side and near_side.name == sidename: return near_side
	if far_side and far_side.name == sidename: return far_side
	var fallback = BattleSide.new(self , 0)
	fallback.name = sidename
	fallback.id = sidename.replace(" ", "")
	return fallback

func add(command: String = ""):
	if command:
		step_queue.append(command)
		
	if at_queue_end and current_step < step_queue.size():
		at_queue_end = false
		next_step()

func instant_add(command: String):
	run(command, true)
	preempt_step_queue.append(command)
	add(command)

func run(line: String, preempt: bool = false) -> void:
	# Manejo de preempt
	if not preempt and preempt_step_queue.size() > 0 and line == preempt_step_queue[0]:
		preempt_step_queue.pop_front()
		scene.preempt_catchup()
		return
	
	if line.is_empty():
		return
	
	var parsed = BattleTextParser.parse_battle_line(line)
	print(parsed)

	var args = parsed.args
	var kwargs = parsed.kwargs
	
	if scene.maybe_close_messagebar(args, kwargs):
		current_step -= 1
		active_move_is_spread = null
		return
	
	# Preparar siguiente línea (para minors)
	var next_args: Array = [""]
	var next_kwargs: Dictionary = {}
	
	var next_line: String = ""
	if current_step + 1 < step_queue.size():
		next_line = step_queue[current_step + 1]
	
	if next_line.begins_with("|-"):
		var next_parsed = BattleTextParser.parse_battle_line(next_line)
		next_args = next_parsed.args
		next_kwargs = next_parsed.kwargs
	
	if debug:
		if args[0].begins_with("-") or args[0] == "detailschange":
			run_minor(args, kwargs, next_args, next_kwargs)
		else:
			run_major(args, kwargs, preempt)
	else:
		# TODO: Aqui el codigo orignal utiliza try catch
		if args[0].begins_with("-") or args[0] == "detailschange":
			run_minor(args, kwargs, next_args, next_kwargs)
		else:
			run_major(args, kwargs, preempt)
	
	if next_line.begins_with("|start") or args[0] == "teampreview":
		if turn == -1:
			turn = 0
			scene.update_bgm()

func set_hardcore_mode(mode: bool):
	hardcore_mode = mode
	if scene and scene.has_method("update_sidebars"):
		scene.update_sidebars()
	if scene and scene.has_method("update_weather"):
		scene.update_weather(true)

func reset_to_current_turn():
	if ended:
		seek_turn(INF, true)
	else:
		seek_turn(turn, true)

func switch_viewpoint():
	set_viewpoint("p1" if viewpoint_switched else "p2")

func set_viewpoint(sideid: String):
	if my_side and my_side.sideid == sideid: return
	if sideid.length() != 2 or not sideid.begins_with("p"): return
	
	var side = null
	if sideid == "p1": side = p1
	elif sideid == "p2": side = p2
	elif sideid == "p3": side = p3
	elif sideid == "p4": side = p4
	
	if not side: return
	my_side = side
	
	if (side.n % 2) == p1.n:
		viewpoint_switched = false
		near_side = p1
		far_side = p2
	else:
		viewpoint_switched = true
		near_side = p2
		far_side = p1
		
	near_side.is_far = false
	far_side.is_far = true
	if sides.size() > 2:
		sides[near_side.n + 2].is_far = false
		sides[far_side.n + 2].is_far = true

func parse_details(name: String, pokemonid: String, details: String) -> Dictionary:
	var output = {}
	var is_team_preview = (name == "")
	output["details"] = details
	output["name"] = name
	output["species_forme"] = name
	output["level"] = 100
	output["shiny"] = false
	output["gender"] = ""
	output["ident"] = pokemonid if not is_team_preview else ""
	output["searchid"] = (pokemonid + "|" + details) if not is_team_preview else ""
	var split_details = details.split(", ")
	
	if split_details[split_details.size() - 1].begins_with("tera:"):
		output["terastallized"] = split_details[split_details.size() - 1].substr(5)
		split_details.remove_at(split_details.size() - 1)
	if split_details[split_details.size() - 1] == "shiny":
		output["shiny"] = true
		split_details.remove_at(split_details.size() - 1)
	if (split_details[split_details.size() - 1] == "M" or split_details[split_details.size() - 1] == "F"):
		output["gender"] = split_details[split_details.size() - 1]
		split_details.remove_at(split_details.size() - 1)
	if split_details[split_details.size() - 1].begins_with("L"):
		var lvl_str = split_details[split_details.size() - 1].substr(1)
		if lvl_str.is_valid_int():
			output["level"] = lvl_str.to_int()
		split_details.remove_at(split_details.size() - 1)
	if split_details.size() > 0:
		output["species_forme"] = split_details[0]
	return output

func parse_health(hpstring: String, output = {}):
	var parts = hpstring.split(" ")
	var hp = parts[0]
	var status = parts[1] if parts.size() > 1 else null

	# parseo de hp
	output.hpcolor = ""

	if hp == "0" or hp == "0.0":
		if not output.has("maxhp") or not output.maxhp:
			output.maxhp = 100
		output.hp = 0

	elif hp.find("/") > 0:
		var hp_parts = hp.split("/")
		var curhp = hp_parts[0]
		var maxhp = hp_parts[1]

		if is_nan(float(curhp)) or is_nan(float(maxhp)):
			return null

		output.hp = float(curhp)
		output.maxhp = float(maxhp)

		if output.hp > output.maxhp:
			output.hp = output.maxhp

		var colorchar = maxhp.substr(maxhp.length() - 1, 1)
		if colorchar == "r" or colorchar == "y" or colorchar == "g":
			output.hpcolor = colorchar

	elif not is_nan(float(hp)):
		if not output.has("maxhp") or not output.maxhp:
			output.maxhp = 100
		output.hp = output.maxhp * float(hp) / 100.0

	# parseo de estado
	if not status:
		output.status = ""

	elif status in ["par", "brn", "slp", "frz", "tox"]:
		output.status = status

	elif status == "psn" and output.status != "tox":
		output.status = status

	elif status == "fnt":
		output.hp = 0
		output.fainted = true

	return output

func run_minor(args: Array, kwargs: Dictionary = {}, next_args: Array = [], next_kwargs: Dictionary = {}):
	if next_args and next_kwargs:
		if args[2] == "Sturdy" and args[0] == "-activate":
			args[2] = "ability: Sturdy"

		if args[0] in ["-crit", "-supereffective", "-resisted"] or args[2] == "ability: Sturdy":
			kwargs.then = "."

		if args[0] == "-damage" and not kwargs.from and args[1] != next_args[1] and (
			next_args[0] in ["-crit", "-supereffective", "-resisted"] or
			(next_args[0] == "-damage" and not next_kwargs.from)
		):
			kwargs.then = "."

		if args[0] == "-damage" and next_args[0] == "-damage" and kwargs.from and kwargs.from == next_kwargs.from:
			kwargs.then = "."

		if args[0] == "-heal" and next_args[0] == "-heal" and kwargs.from and kwargs.from == next_kwargs.from:
			kwargs.then = "."

		if args[0] == "-ability" and (args[2] == "Intimidate" or args[4] == "boost"):
			kwargs.then = "."

		if args[0] == "-unboost" and next_args[0] == "-unboost":
			kwargs.then = "."

		if args[0] == "-boost" and next_args[0] == "-boost":
			kwargs.then = "."

		if args[0] == "-damage" and kwargs.from == "Leech Seed" and next_args[0] == "-heal" and next_kwargs.silent:
			kwargs.then = "."

		if args[0] == "detailschange" and next_args[0] == "-mega":
			if scene.close_messagebar():
				current_step -= 1
				return
			kwargs.simult = "."

	if kwargs.has("then") and kwargs.then:
		wait_for_animations = false

	if kwargs.has("simult") and kwargs.simult:
		wait_for_animations = "simult"
	
	_run_minor(args, kwargs, next_args, next_kwargs)

func _run_minor(args: Array, kwargs: Dictionary = {}, next_args: Array = [], next_kwargs: Dictionary = {}):
	const CONSUMED = ["eaten", "popped", "consumed", "held up"]

	match args[0]:
		"-damage":
			var poke = get_pokemon(args[1])
			var damage = poke.health_parse(args[2], true)
			if damage == null:
				return

			var range = poke.get_damage_range(damage)

			if kwargs.has("from"):
				var effect = Dex.get_effect(kwargs.from)
				var of_poke = get_pokemon(kwargs.of)

				activate_ability(of_poke, effect)

				if effect.effect_type == "Item":
					var item_poke = of_poke if of_poke != null else poke
					if item_poke.prev_item != effect.name and not (item_poke.prev_item_effect in CONSUMED):
						item_poke.item = effect.name

				match effect.id:
					"brn":
						scene.run_status_anim("brn", [poke])
					"psn":
						scene.run_status_anim("psn", [poke])
					"baddreams", "curse":
						scene.run_status_anim("cursed", [poke])
					"confusion":
						scene.run_status_anim("confusedselfhit", [poke])
					"leechseed":
						scene.run_other_anim("leech", [of_poke, poke])
					"bind", "wrap":
						scene.run_other_anim("bound", [poke])
			else:
				if dex.get_move(last_move).category != "Status":
					poke.times_attacked += 1

				var damage_info = "" + Pokemon.get_formatted_range(range, 0 if damage[1] == 100 else 1, "–")

				if damage[1] != 100:
					var hover = ("%s%d/%d" % [
						"−" if damage[0] < 0 else "",
						abs(damage[0]),
						damage[1]
					])

					if damage[1] == 48:
						hover += " pixels"

					damage_info = "||" + hover + "||" + damage_info + "||"

				args[3] = damage_info

			scene.damage_anim(poke, Pokemon.get_formatted_range(range, 0, " to "))
			add_log(args, kwargs)

		"-heal":
			var poke = get_pokemon(args[1], Dex.get_effect(kwargs.from).id == "revivalblessing")
			var damage = poke.health_parse(args[2], true, true)
			if damage == null:
				return

			var range = poke.get_damage_range(damage)

			if kwargs.from:
				var effect = Dex.get_effect(kwargs.from)
				var of_poke = get_pokemon(kwargs.of)

				activate_ability(of_poke if of_poke != null else poke, effect)

				if effect.effect_type == "Item" and not (poke.prev_item_effect in CONSUMED):
					if poke.prev_item != effect.name:
						poke.item = effect.name

				match effect.id:
					"lunardance":
						for tracked_move in poke.move_track:
							tracked_move[1] = 0
						# fallthrough

					"healingwish":
						last_move = "healing-wish"
						scene.run_residual_anim("healingwish", poke)
						poke.side.wisher = null
						poke.status_data.sleep_turns = 0
						poke.status_data.toxic_turns = 0

					"wish":
						scene.run_residual_anim("wish", poke)

					"revivalblessing":
						scene.run_residual_anim("wish", poke)
						var parsed = parse_pokemon_id(args[1])
						var side = sides[parsed.siden]

						poke.fainted = false
						poke.status = ""
						scene.update_sidebar(side)

			scene.run_other_anim("heal", [poke])
			scene.heal_anim(poke, Pokemon.get_formatted_range(range, 0, " to "))
			add_log(args, kwargs)

		"-enditem":
			var poke = get_pokemon(args[1])
			var item = Dex.get_item(args[2])
			var effect = Dex.get_effect(kwargs.get("from"))

			if gen > 4 or effect.id != "knockoff":
				poke.item = ""
				poke.item_effect = ""
				poke.prev_item = item.name
				poke.prev_item_effect = ""

			poke.remove_volatile("airballoon")
			poke.add_volatile("itemremoved")

			if kwargs.has("eat"):
				poke.prev_item_effect = "eaten"
				scene.run_other_anim("consume", [poke])
				last_move = item.id

			elif kwargs.has("weaken"):
				poke.prev_item_effect = "eaten"
				last_move = item.id

			elif effect.id:
				match effect.id:
					"fling":
						poke.prev_item_effect = "flung"

					"knockoff":
						if gen <= 4:
							poke.item_effect = "knocked off"
						else:
							poke.prev_item_effect = "knocked off"

						scene.run_other_anim("itemoff", [poke])
						scene.result_anim(poke, "Item knocked off", "neutral")

					"stealeat":
						poke.prev_item_effect = "stolen"

					"gem":
						poke.prev_item_effect = "consumed"

					"incinerate":
						poke.prev_item_effect = "incinerated"

			else:
				match item.id:
					"airballoon":
						poke.prev_item_effect = "popped"
						poke.remove_volatile("airballoon")
						scene.result_anim(poke, "Balloon popped", "neutral")

					"focussash":
						poke.prev_item_effect = "consumed"
						scene.result_anim(poke, "Sash", "neutral")

					"focusband":
						scene.result_anim(poke, "Focus Band", "neutral")

					"redcard":
						poke.prev_item_effect = "held up"

					_:
						poke.prev_item_effect = "consumed"

			add_log(args, kwargs)
func parse_sprite_data(data: Dictionary) -> void:
	assert(false, "not implemented yet")

func remember_team_preview_pokemon() -> void:
	assert(false, "not implemented yet")

func find_corresponding_pokemon(poke: Pokemon) -> Pokemon:
	assert(false, "not implemented yet")
	return null

func ngas_active() -> bool:
	assert(false, "not implemented yet")
	return false

func check_active(poke) -> bool:
	if not poke.side.active[poke.slot]:
		# SOMEONE jumped in in the middle of a replay. <_<
		poke.side.replace(poke)

	return false

func pause() -> void:
	assert(false, "not implemented yet")

func play() -> void:
	assert(false, "not implemented yet")

func skip_turn() -> void:
	assert(false, "not implemented yet")

func seek_by(amount: int) -> void:
	assert(false, "not implemented yet")

func seek_turn(turn_number: int, skip_to_next: bool = false) -> void:
	assert(false, "not implemented yet")

func stop_seeking():
	seeking = null
	scene.animation_on()

	if subscription:
		subscription.call("paused" if paused else "playing")

func should_step() -> bool:
	if at_queue_end:
		return false

	if seeking != null:
		return true

	var battle_started = turn >= 0
	return not (paused and battle_started)

func next_step():
	if not should_step():
		return

	var time = Time.get_ticks_msec()
	scene.start_animations()
	var animations = null

	var interruption_count

	while true:
		wait_for_animations = true

		if current_step >= step_queue.size():
			at_queue_end = true

			if not ended and is_replay:
				premature_end()

			stop_seeking()

			if ended:
				scene.update_bgm()

			if subscription:
				subscription.call("atqueueend")

			return

		run(step_queue[current_step])
		current_step += 1

		if wait_for_animations == true:
			animations = scene.finish_animations()
		elif wait_for_animations == "simult":
			scene.time_offset = 0

		if Time.get_ticks_msec() - time > 300:
			interruption_count = scene.interruption_count

			await Engine.get_main_loop().create_timer(0.001).timeout

			if interruption_count == scene.interruption_count:
				next_step()
			return

		if animations or not should_step():
			break

	if paused and turn >= 0 and seeking == null:
		scene.pause()
		return

	if not animations:
		return

	interruption_count = scene.interruption_count

	animations.done(func():
		if interruption_count == scene.interruption_count:
			next_step()
	)

func set_timeout(timeout: int) -> void:
	assert(false, "not implemented yet")

func set_queue(queue_lines: Array) -> void:
	assert(false, "not implemented yet")

func set_mute(mute_flag: bool) -> void:
	assert(false, "not implemented yet")

enum HPColor {
	NONE,
	R,
	Y,
	G,
}
enum StatusName {
	PAR,
	PSN,
	FRZ,
	SLP,
	BRN,
	TOX,
	NONE,
	UNKNOWN,
}

class BattleTextParser:
	static func parse_battle_line(line: String) -> Dictionary:
		var parts = line.split("|")
		var args = []
		var kwargs = {}
		if parts.size() > 1:
			for i in range(1, parts.size()):
				var p = parts[i]
				if p.begins_with("[") and p.contains("]"):
					var end_idx = p.find("]")
					var key = p.substr(1, end_idx - 1)
					var val = p.substr(end_idx + 1).strip_edges()
					kwargs[key] = val
				else:
					args.append(p)
		elif parts.size() == 1:
			args.append(parts[0])
		return {"args": args, "kwargs": kwargs}

class BattleSceneLog:
	func add(args: Array, kwargs: Dictionary = {}, preempt: bool = false):
		pass

class BattleScene:
	var log = BattleSceneLog.new()
	var animating: bool = false
	var acceleration: float = NAN
	var gen: float = NAN
	var active_count: float = NAN
	var numeric_id: float = NAN
	var time_offset: float = NAN
	var interruption_count: float = NAN
	var messagebar_open: bool = false
	var frame: Variant = null

	func ability_activate_anim(pokemon: Pokemon, result: String) -> void: pass
	func add_pokemon_sprite(pokemon: Pokemon) -> PokemonSprite: return null
	func add_side_condition(siden: int, id: String, instant: bool = false) -> void: pass
	func animation_off() -> void: pass
	func animation_on() -> void: pass
	func maybe_close_messagebar(args: Array, kw_args: Dictionary) -> bool: return false
	func close_messagebar() -> bool: return false
	func damage_anim(pokemon: Pokemon, damage: Variant) -> void: pass
	func destroy() -> void: pass
	func finish_animations() -> Variant: return null
	func heal_anim(pokemon: Pokemon, damage: Variant) -> void: pass
	func hide_join_buttons() -> void: pass
	func increment_turn() -> void: pass
	func update_acceleration() -> void: pass
	func message(message: String, hidden_message: String = "") -> void: pass
	func pause() -> void: pass
	func set_mute(muted: bool) -> void: pass
	func preempt_catchup() -> void: pass
	func remove_side_condition(siden: int, id: String) -> void: pass
	func reset() -> void: pass
	func reset_bgm() -> void: pass
	func update_bgm() -> void: pass
	func result_anim(
		pokemon:Pokemon, result: String, type: String
	) -> void: pass
	func type_anim(pokemon: Pokemon, types: String) -> void: pass
	func resume() -> void: pass
	func run_move_anim(moveid: String, participants: Array[Pokemon]) -> void: pass
	func run_other_anim(moveid: String, participants: Array[Pokemon]) -> void: pass
	func run_prepare_anim(moveid: String, attacker: Pokemon, defender: Pokemon) -> void: pass
	func run_residual_anim(moveid: String, pokemon: Pokemon) -> void: pass
	func run_status_anim(moveid: String, participants: Array[Pokemon]) -> void: pass
	func start_animations() -> void: pass
	func team_preview() -> void: pass
	func reset_sides() -> void: pass
	func update_gen() -> void: pass
	func update_sidebar(side: BattleSide) -> void: pass
	func update_sidebars() -> void: pass
	func update_statbars() -> void: pass
	func update_weather(instant: bool = false) -> void: pass
	func upkeep_weather() -> void: pass
	func wait(time: float) -> void: pass
	func set_frame_html(html: Variant) -> void: pass
	func set_controls_html(html: Variant) -> void: pass
	func remove_effect(pokemon: Pokemon, id: String, instant: bool = false) -> void: pass
	func add_effect(pokemon: Pokemon, id: String, instant: bool = false) -> void: pass
	func anim_summon(pokemon: Pokemon, slot: int, instant: bool = false) -> void: pass
	func anim_unsummon(pokemon: Pokemon, instant: bool = false) -> void: pass
	func anim_drag_in(pokemon: Pokemon, slot: int) -> void: pass
	func anim_drag_out(pokemon: Pokemon) -> void: pass
	func reset_statbar(pokemon: Pokemon, start_hidden: bool = false) -> void: pass
	func update_statbar(pokemon: Pokemon, update_prevhp: bool = false, update_hp: bool = false) -> void: pass
	func update_statbar_if_exists(pokemon: Pokemon, update_prevhp: bool = false, update_hp: bool = false) -> void: pass
	func anim_transform(pokemon: Pokemon, use_species_anim: bool = false, is_permanent: bool = false) -> void: pass
	func clear_effects(pokemon: Pokemon) -> void: pass
	func remove_transform(pokemon: Pokemon) -> void: pass
	func anim_faint(pokemon: Pokemon) -> void: pass
	func anim_reset(pokemon: Pokemon) -> void: pass
	func anim(pokemon: Pokemon, end: Vector2, transition: String = "") -> void: pass
	func before_move(pokemon: Pokemon) -> void: pass
	func after_move(pokemon: Pokemon) -> void: pass

class ServerPokemon extends Serializable:
	# PokemonDetails
	var details: String
	var name: String
	var species_forme: String
	var level: int
	var shiny: bool
	var gender: String
	var ident: String
	var searchid: String
	
	# PokemonHealth
	var hp: int
	var maxhp: int
	var hpcolor: HPColor
	var status: StatusName
	var fainted: bool
	
	# ServerPokemon specifics
	var condition: String
	var active: bool
	var reviving: bool
	var stats: Dictionary
	var moves: Array[String] = []
	var base_ability: String
	var ability: String
	var item: String
	var pokeball: String
	var tera_type: String
	var terastallized: String
	
	func _init(json_data: Dictionary = {}):
		super (json_data)

class BattleSide:
	var battle: Battle
	var name: String = ""
	var id: String = ""
	var sideid: String = ""
	var n: int = 0
	var is_far: bool = false
	var foe: BattleSide = null
	var ally: BattleSide = null
	var avatar: String = "unknown"
	var badges: Array[String] = []
	var rating: String = ""
	var total_pokemon: int = 6
	var x: float = 0
	var y: float = 0
	var z: float = 0
	var missed_pokemon: Pokemon = null

	var wisher: Pokemon = null

	var active: Array[Pokemon] = [null]
	var last_pokemon: Pokemon = null
	var pokemon: Array[Pokemon] = []

	var side_conditions: Dictionary = {}
	var faint_counter: int = 0

	func _init(_battle: Battle = null, _n: int = 0):
		self.battle = _battle
		self.n = _n
		var sides = ["p1", "p2", "p3", "p4"]
		self.sideid = sides[_n] if _n < sides.size() else ""
		self.is_far = bool(_n % 2)

	func roll_trainer_sprites():
		var sprites = ["lucas", "dawn", "ethan", "lyra", "hilbert", "hilda"]
		self.avatar = sprites[randi() % sprites.size()]

	func behindx(offset: float) -> float:
		return x + (-1 if not is_far else 1) * offset

	func behindy(offset: float) -> float:
		return y + (1 if not is_far else -1) * offset

	func leftof(offset: float) -> float:
		return (-1 if not is_far else 1) * offset

	func behind(offset: float) -> float:
		return z + (-1 if not is_far else 1) * offset

	func clear_pokemon():
		for p in pokemon:
			if p:
				p.destroy()
		pokemon.clear()
		for i in range(active.size()):
			active[i] = null
		last_pokemon = null

	func reset():
		clear_pokemon()
		side_conditions.clear()
		faint_counter = 0

	func set_avatar(_avatar: String):
		self.avatar = _avatar

	func set_name(_name: String, _avatar: String = ""):
		if _name:
			self.name = _name
		self.id = self.name.to_lower().replace(" ", "")
		if _avatar:
			set_avatar(_avatar)
		else:
			roll_trainer_sprites()
			if foe and self.avatar == foe.avatar:
				roll_trainer_sprites()

	func add_side_condition(effect: Dictionary, persist: bool = false):
		var condition = effect.get("id", "")
		if side_conditions.has(condition):
			if condition == "spikes" or condition == "toxicspikes":
				side_conditions[condition][1] += 1
			if battle and battle.has_method("scene") and battle.scene:
				battle.scene.add_side_condition(n, condition)
			return

		var effect_name = effect.get("name", condition)
		match condition:
			"auroraveil":
				side_conditions[condition] = [effect_name, 1, 5, 8]
			"reflect", "lightscreen":
				var gen = battle.gen if battle and "gen" in battle else 8
				side_conditions[condition] = [effect_name, 1, 5, 8 if gen >= 4 else 0]
			"safeguard":
				side_conditions[condition] = [effect_name, 1, 7 if persist else 5, 0]
			"mist", "luckychant":
				side_conditions[condition] = [effect_name, 1, 5, 0]
			"tailwind":
				var duration = 0
				var gen = battle.gen if battle and "gen" in battle else 8
				if gen >= 5:
					duration = 6 if persist else 4
				else:
					duration = 5 if persist else 3
				side_conditions[condition] = [effect_name, 1, duration, 0]
			"stealthrock", "spikes", "toxicspikes", "stickyweb":
				side_conditions[condition] = [effect_name, 1, 0, 0]
			"gmaxwildfire", "gmaxvolcalith", "gmaxvinelash", "gmaxcannonade":
				side_conditions[condition] = [effect_name, 1, 4, 0]
			"grasspledge":
				side_conditions[condition] = ["Swamp", 1, 4, 0]
			"waterpledge":
				side_conditions[condition] = ["Rainbow", 1, 4, 0]
			"firepledge":
				side_conditions[condition] = ["Sea of Fire", 1, 4, 0]
			_:
				side_conditions[condition] = [effect_name, 1, 0, 0]
		
		if battle and battle.has_method("scene") and battle.scene:
			battle.scene.add_side_condition(n, condition)

	func remove_side_condition(condition: String):
		var id = condition.to_lower().replace(" ", "")
		if not side_conditions.has(id):
			return
		side_conditions.erase(id)
		if battle and battle.has_method("scene") and battle.scene:
			battle.scene.remove_side_condition(n, id)

	func add_pokemon(_name: String, ident: String, details: String, replace_slot: int = -1) -> Pokemon:
		var old_pokemon: Pokemon = pokemon[replace_slot] if replace_slot >= 0 and replace_slot < pokemon.size() else null

		var data = battle.parse_details(_name, ident, details)
		var poke = Pokemon.new(data, self)
		if old_pokemon:
			poke.item = old_pokemon.item
			poke.base_ability = old_pokemon.base_ability
			poke.teraType = old_pokemon.teraType

		if not poke.ability and poke.base_ability:
			poke.ability = poke.base_ability
		poke.reset()
		if old_pokemon and old_pokemon.move_track.size() > 0:
			poke.move_track = old_pokemon.move_track.duplicate(true)

		if replace_slot >= 0:
			while pokemon.size() <= replace_slot:
				pokemon.append(null)
			pokemon[replace_slot] = poke
		else:
			pokemon.append(poke)

		var species_clause = battle.species_clause if battle and "species_clause" in battle else false
		if pokemon.size() > total_pokemon or species_clause:
			var existing_table: Dictionary = {}
			var to_remove: int = -1
			for poke1i in range(pokemon.size()):
				var poke1 = pokemon[poke1i]
				if not poke1 or not poke1.searchid: continue
				if existing_table.has(poke1.searchid):
					var poke2i = existing_table[poke1.searchid]
					var poke2 = pokemon[poke2i]
					if poke == poke1:
						to_remove = poke2i
					elif poke == poke2:
						to_remove = poke1i
					elif active.has(poke1):
						to_remove = poke2i
					elif active.has(poke2):
						to_remove = poke1i
					elif poke1.fainted and not poke2.fainted:
						to_remove = poke2i
					else:
						to_remove = poke1i
					break
				existing_table[poke1.searchid] = poke1i
			
			if to_remove >= 0:
				if pokemon[to_remove] and pokemon[to_remove].fainted:
					var illusion_found: Pokemon = null
					for cur_poke in pokemon:
						if not cur_poke or cur_poke == poke or cur_poke.fainted or active.has(cur_poke): continue
						if cur_poke.species_forme == "Zoroark" or cur_poke.species_forme == "Zorua" or cur_poke.ability == "Illusion":
							illusion_found = cur_poke
							break
					if not illusion_found:
						for cur_poke in pokemon:
							if not cur_poke or cur_poke == poke or cur_poke.fainted or active.has(cur_poke): continue
							illusion_found = cur_poke
							break
					if illusion_found:
						illusion_found.fainted = true
						illusion_found.hp = 0
						illusion_found.status = StatusName.NONE
				pokemon.remove_at(to_remove)
				
		if battle and battle.has_method("scene") and battle.scene:
			battle.scene.update_sidebar(self )

		return poke

	func switch_in(poke: Pokemon, kwargs: Dictionary, slot: int = -1):
		if slot == -1: slot = poke.slot
		while active.size() <= slot:
			active.append(null)
			
		active[slot] = poke
		poke.slot = slot
		poke.clear_volatile()
		poke.last_move = ""
		if battle:
			battle.last_move = "switch-in"
		var effect_id = kwargs.get("from", "")
		if effect_id in ["batonpass", "zbatonpass", "shedtail"]:
			if last_pokemon:
				poke.copy_volatile_from(last_pokemon, "shedtail" if effect_id == "shedtail" else false)
		elif battle and "tier" in battle and typeof(battle.tier) == TYPE_STRING and battle.tier.contains("Relay Race") and effect_id == "":
			if last_pokemon and not last_pokemon.fainted:
				poke.copy_volatile_from(last_pokemon, false)

		if battle and battle.has_method("scene") and battle.scene:
			battle.scene.anim_summon(poke, slot)

	func drag_in(poke: Pokemon, slot: int = -1):
		if slot == -1: slot = poke.slot
		while active.size() <= slot:
			active.append(null)
			
		var oldpokemon = active[slot]
		if oldpokemon == poke: return
		last_pokemon = oldpokemon
		if oldpokemon:
			if battle and battle.has_method("scene") and battle.scene:
				battle.scene.anim_drag_out(oldpokemon)
			oldpokemon.clear_volatile()
		poke.clear_volatile()
		poke.lastMove = ""
		if battle:
			battle.lastMove = "switch-in"
		active[slot] = poke
		poke.slot = slot

		if battle and battle.has_method("scene") and battle.scene:
			battle.scene.anim_drag_in(poke, slot)

	func replace(poke: Pokemon, slot: int = -1):
		if slot == -1: slot = poke.slot
		while active.size() <= slot:
			active.append(null)
			
		var oldpokemon = active[slot]
		if poke == oldpokemon: return
		last_pokemon = oldpokemon
		poke.clear_volatile()
		if oldpokemon:
			poke.lastMove = oldpokemon.lastMove
			poke.hp = oldpokemon.hp
			poke.maxhp = oldpokemon.maxhp
			poke.hpcolor = oldpokemon.hpcolor
			poke.status = oldpokemon.status
			poke.copy_volatile_from(oldpokemon, true)
			poke.status_data = oldpokemon.status_data.duplicate(true)
			if oldpokemon.terastallized:
				poke.terastallized = oldpokemon.terastallized
				poke.teraType = oldpokemon.terastallized
				oldpokemon.terastallized = ""
				oldpokemon.teraType = ""
			oldpokemon.fainted = false
			oldpokemon.hp = oldpokemon.maxhp
			oldpokemon.status = StatusName.UNKNOWN
			
		active[slot] = poke
		poke.slot = slot

		if battle and battle.has_method("scene") and battle.scene:
			if oldpokemon:
				battle.scene.anim_unsummon(oldpokemon, true)
			battle.scene.anim_summon(poke, slot, true)

	func switch_out(poke: Pokemon, kwargs: Dictionary, slot: int = -1):
		if slot == -1: slot = poke.slot
		var effect_id = kwargs.get("from", "")
		if not effect_id in ["batonpass", "zbatonpass", "shedtail"] and not (battle and "tier" in battle and typeof(battle.tier) == TYPE_STRING and battle.tier.contains("Relay Race") and effect_id == ""):
			poke.clear_volatile()
		else:
			poke.remove_volatile("transform")
			poke.remove_volatile("formechange")
			
		if not effect_id in ["batonpass", "zbatonpass", "shedtail", "teleport"] and not (battle and "tier" in battle and typeof(battle.tier) == TYPE_STRING and battle.tier.contains("Relay Race") and effect_id == ""):
			battle.add_log(["switchout", poke.ident], {"from": effect_id})
				
		poke.status_data["toxicTurns"] = 0
		if battle and "gen" in battle and battle.gen == 5:
			poke.status_data["sleepTurns"] = 0
		last_pokemon = poke
		if slot < active.size():
			active[slot] = null

		battle.scene.anim_unsummon(poke)

	func swap_to(poke: Pokemon, slot: int):
		if poke.slot == slot: return
		while active.size() <= max(slot, poke.slot):
			active.append(null)
			
		var target = active[slot]
		var oslot = poke.slot

		poke.slot = slot
		if target: target.slot = oslot

		active[slot] = poke
		active[oslot] = target

		if battle and battle.has_method("scene") and battle.scene:
			battle.scene.anim_unsummon(poke, true)
			if target: battle.scene.anim_unsummon(target, true)
			battle.scene.anim_summon(poke, slot, true)
			if target: battle.scene.anim_summon(target, oslot, true)

	func swap_with(poke: Pokemon, target: Pokemon, kwargs: Dictionary):
		if poke == target: return

		var oslot = poke.slot
		var nslot = target.slot

		poke.slot = nslot
		target.slot = oslot
		while active.size() <= max(nslot, oslot):
			active.append(null)
			
		active[nslot] = poke
		active[oslot] = target

		if battle and battle.has_method("scene") and battle.scene:
			battle.scene.anim_unsummon(poke, true)
			battle.scene.anim_unsummon(target, true)
			battle.scene.anim_summon(poke, nslot, true)
			battle.scene.anim_summon(target, oslot, true)

	func faint(poke: Pokemon, slot: int = -1):
		if slot == -1: slot = poke.slot
		poke.clear_volatile()
		last_pokemon = poke
		if slot < active.size():
			active[slot] = null

		poke.fainted = true
		poke.hp = 0
		poke.terastallized = ""
		# regex string replacement
		var regex = RegEx.new()
		regex.compile(", tera:[a-z]+")
		poke.details = regex.sub(poke.details, "", true)
		poke.searchid = regex.sub(poke.searchid, "", true)
		
		if poke.side and poke.side.faint_counter < 100:
			poke.side.faint_counter += 1

		if battle and battle.has_method("scene") and battle.scene:
			battle.scene.anim_faint(poke)

	func destroy():
		clear_pokemon()
		battle = null
		foe = null

class PokemonSprite:
	func destroy():
		pass

class Pokemon:
	var name: String = ""
	var species_forme: String = ""
	var ident: String = ""
	var details: String = ""
	var searchid: String = ""
	
	var side: BattleSide
	var slot: int = 0
	
	var fainted: bool = false
	var hp: int = 0
	var maxhp: int = 1000
	var level: int = 100
	var gender: String = "N"
	var shiny: bool = false
	
	var hpcolor: HPColor = HPColor.G
	var moves: Array[String] = []
	var ability: String = ""
	var base_ability: String = ""
	var item: String = ""
	var item_effect: String = ""
	var prev_item: String = ""
	var prev_item_effect: String = ""
	var terastallized: String = ""
	var tera_type: String = ""
	
	var boosts: Dictionary = {}
	var status: StatusName = StatusName.NONE
	var status_stage: int = 0
	var volatiles: Dictionary = {}
	var turnstatuses: Dictionary = {}
	var movestatuses: Dictionary = {}
	var last_move: String = ""
	
	var move_track: Array = []
	var status_data: Dictionary = {"sleepTurns": 0, "toxicTurns": 0}
	var times_attacked: int = 0
	
	var sprite: PokemonSprite
	
	func _init(data: Dictionary, p_side: BattleSide):
		side = p_side
		species_forme = data.species_forme
		details = data.details
		name = data.name
		level = data.level
		shiny = data.shiny
		gender = data.gender if data.gender != "" else "N"
		ident = data.ident
		terastallized = data.get("terastallized", "")
		searchid = data.searchid
		
	func is_active() -> bool:
		return side.active.has(self )
		
	func get_hp_color() -> HPColor:
		if hpcolor != HPColor.NONE: return hpcolor
		var ratio: float = float(hp) / float(maxhp)
		if ratio > 0.5: return HPColor.G
		if ratio > 0.2: return HPColor.Y
		return HPColor.R

	func get_hp_color_class() -> String:
		match get_hp_color():
			HPColor.Y: return "hpbar hpbar-yellow"
			HPColor.R: return "hpbar hpbar-red"
		return "hpbar"
		
	static func get_pixel_range(pixels: int, color: HPColor) -> Array:
		var epsilon: float = 0.5 / 714.0
		
		if pixels == 0: return [0.0, 0.0]
		if pixels == 1: return [0.0 + epsilon, 2.0 / 48.0 - epsilon]
		if color != HPColor.NONE:
			if pixels == 9:
				if color == HPColor.Y:
					return [0.2 + epsilon, 10.0 / 48.0 - epsilon]
				elif color == HPColor.R:
					return [9.0 / 48.0, 0.2]
			if pixels == 24:
				if color == HPColor.G:
					return [0.5 + epsilon, 25.0 / 48.0 - epsilon]
				elif color == HPColor.Y:
					return [0.5, 0.5]
		if pixels == 48: return [1.0, 1.0]
		
		return [pixels / 48.0, (pixels + 1.0) / 48.0 - epsilon]
		
	static func get_formatted_range(range_vals: Array, precision: int, separator: String) -> String:
		if range_vals[0] == range_vals[1]:
			var percentage: float = abs(range_vals[0] * 100.0)
			if floor(percentage) == percentage:
				return str(percentage) + "%"
			return "%.*f" % [precision, percentage] + "%"
		var lower: String
		var upper: String
		if precision == 0:
			lower = str(floor(range_vals[0] * 100.0))
			upper = str(ceil(range_vals[1] * 100.0))
		else:
			lower = "%.*f" % [precision, range_vals[0] * 100.0]
			upper = "%.*f" % [precision, range_vals[1] * 100.0]
		return lower + separator + upper

	func get_damage_range(damage: Array) -> Array:
		if damage[1] != 48:
			var ratio: float = float(damage[0]) / float(damage[1])
			return [ratio, ratio]
		elif damage.size() == 3:
			return [float(damage[2]) / 100.0, float(damage[2]) / 100.0]
			
		var oldrange: Array = Pokemon.get_pixel_range(damage[3], damage[4] if damage.size() > 4 else HPColor.NONE)
		var newrange: Array = Pokemon.get_pixel_range(damage[3] + damage[0], hpcolor)
		if damage[0] == 0:
			return [0.0, newrange[1] - newrange[0]]
		if oldrange[0] < newrange[0]:
			var r = oldrange
			oldrange = newrange
			newrange = r
		return [oldrange[0] - newrange[1], oldrange[1] - newrange[0]]

	func health_parse(hpstring: String, parsedamage: bool = false, heal: bool = false):
		# retorna [delta, denominator, percent(, oldnum, oldcolor)] o null
		if not hpstring or hpstring.length() == 0:
			return null

		var paren_index = hpstring.rfind("(")

		if paren_index >= 0:
			# estilo antiguo de daño y vida
			if parsedamage:
				var damage = float(hpstring)
				if is_nan(damage):
					damage = 50.0

				if heal:
					hp += maxhp * damage / 100.0
					if hp > maxhp:
						hp = maxhp
				else:
					hp -= maxhp * damage / 100.0

				# parsear info absoluta
				var ret = health_parse(hpstring)
				if ret and ret[1] == 100:
					return [damage, 100, damage]

				var percent = round(ceil(damage * 48.0 / 100.0) / 48.0 * 100.0)
				var pixels = ceil(damage * 48.0 / 100.0)
				return [pixels, 48, percent]

			if hpstring.substr(hpstring.length() - 1, 1) != ")":
				return null

			hpstring = hpstring.substr(paren_index + 1, hpstring.length() - paren_index - 2)

		var old_hp = 0 if fainted else (hp if hp != 0 else 1)
		var old_maxhp = maxhp
		var old_width = hp_width(100)
		var old_color = hpcolor

		side.battle.parse_health(hpstring, self)

		if old_maxhp == 0:
			old_maxhp = maxhp
			old_hp = maxhp

		var old_num = int(floor(maxhp * old_hp / old_maxhp)) if old_hp else 0
		if old_hp and old_num == 0:
			old_num = 1

		var delta = hp - old_num
		var delta_width = hp_width(100) - old_width

		return [delta, maxhp, delta_width, old_num, old_color]

	func check_details(p_details: String = "") -> bool:
		if p_details == "": return false
		if p_details == details: return true
		if searchid != "": return false
		if ", shiny" in p_details:
			if check_details(p_details.replace(", shiny", "")): return true
		return false
		
	func get_ident() -> String:
		var slots = ["a", "b", "c", "d", "e", "f"]
		return ident.substr(0, 2) + slots[slot] + ident.substr(2)
		
	func remove_volatile(volatile: String):
		if not has_volatile(volatile): return
		volatiles.erase(volatile)
		
	func add_volatile(volatile: String, args: Array = []):
		if has_volatile(volatile) and args.is_empty(): return
		volatiles[volatile] = [volatile] + args
		
	func has_volatile(volatile: String) -> bool:
		return volatiles.has(volatile)
		
	func remove_turnstatus(volatile: String):
		if not has_turnstatus(volatile): return
		turnstatuses.erase(volatile)
		
	func add_turnstatus(volatile: String):
		if has_turnstatus(volatile): return
		turnstatuses[volatile] = [volatile]
		
	func has_turnstatus(volatile: String) -> bool:
		return turnstatuses.has(volatile)
		
	func clear_turnstatuses():
		turnstatuses.clear()
		
	func remove_movestatus(volatile: String):
		if not has_movestatus(volatile): return
		movestatuses.erase(volatile)
		
	func add_movestatus(volatile: String):
		if has_movestatus(volatile): return
		movestatuses[volatile] = [volatile]
		
	func has_movestatus(volatile: String) -> bool:
		return movestatuses.has(volatile)
		
	func clear_movestatuses():
		movestatuses.clear()
		
	func clear_volatiles():
		volatiles.clear()
		clear_turnstatuses()
		clear_movestatuses()
		
	func remember_move(move_name: String, pp: int = 1, recursion_source: String = ""):
		if recursion_source == ident: return
		if move_name.begins_with("*"): return
		if move_name == "Struggle": return
		
		if volatiles.has("transform"):
			if recursion_source == "": recursion_source = ident
			volatiles["transform"][1].remember_move(move_name, 0, recursion_source)
			move_name = "*" + move_name
			
		for entry in move_track:
			if move_name == entry[0]:
				entry[1] += pp
				if entry[1] < 0: entry[1] = 0
				return
		move_track.append([move_name, pp])
		
	func remember_ability(p_ability: String, is_not_base: bool = false):
		ability = p_ability
		if base_ability == "" and not is_not_base:
			base_ability = p_ability
			
	func get_boost(boost_stat: String) -> String:
		var boost_stat_table = {
			"atk": "Atk", "def": "Def", "spa": "SpA", "spd": "SpD",
			"spe": "Spe", "accuracy": "Accuracy", "evasion": "Evasion", "spc": "Spc"
		}
		if not boosts.has(boost_stat):
			return "1x " + boost_stat_table.get(boost_stat, boost_stat)
			
		var val = boosts[boost_stat]
		if val > 6: val = 6
		if val < -6: val = -6
		
		if boost_stat == "accuracy" or boost_stat == "evasion":
			if val > 0:
				var good = ["1x", "1.33x", "1.67x", "2x", "2.33x", "2.67x", "3x"]
				return good[val] + " " + boost_stat_table.get(boost_stat, boost_stat)
			else:
				var bad = ["1x", "0.75x", "0.6x", "0.5x", "0.43x", "0.38x", "0.33x"]
				return bad[-val] + " " + boost_stat_table.get(boost_stat, boost_stat)
				
		if val > 0:
			var good = ["1x", "1.5x", "2x", "2.5x", "3x", "3.5x", "4x"]
			return good[val] + " " + boost_stat_table.get(boost_stat, boost_stat)
			
		var bad = ["1x", "0.67x", "0.5x", "0.4x", "0.33x", "0.29x", "0.25x"]
		return bad[-val] + " " + boost_stat_table.get(boost_stat, boost_stat)
		
	func get_weight_kg(server_pokemon: ServerPokemon = null) -> float:
		var autotomize_factor = (volatiles["autotomize"][1] * 100) if volatiles.has("autotomize") else 0
		return max(0.1, 10.0 - autotomize_factor)
		
	func get_boost_type(boost_stat: String) -> String:
		if not boosts.has(boost_stat): return "neutral"
		if boosts[boost_stat] > 0: return "good"
		return "bad"
		
	func clear_volatile():
		ability = base_ability
		boosts.clear()
		clear_volatiles()
		var new_track = []
		for entry in move_track:
			if not entry[0].begins_with("*"):
				new_track.append(entry)
		move_track = new_track
		status_stage = 0
		status_data["toxicTurns"] = 0
		
	func copy_volatile_from(pokemon: Pokemon, copy_source = null):
		boosts = pokemon.boosts.duplicate()
		volatiles = pokemon.volatiles.duplicate()
		if copy_source == null or (typeof(copy_source) == TYPE_BOOL and copy_source == false):
			var volatiles_to_remove = [
				"airballoon", "attract", "autotomize", "disable", "encore", "foresight",
				"gmaxchistrike", "imprison", "laserfocus", "mimic", "miracleeye", "nightmare",
				"saltcure", "smackdown", "stockpile1", "stockpile2", "stockpile3", "syrupbomb",
				"torment", "typeadd", "typechange", "yawn"
			]
			for v in volatiles_to_remove:
				volatiles.erase(v)
		if typeof(copy_source) == TYPE_STRING and copy_source == "shedtail":
			var new_vols = {}
			if volatiles.has("substitute"):
				new_vols["substitute"] = volatiles["substitute"]
			volatiles = new_vols
			boosts.clear()
			
		volatiles.erase("transform")
		volatiles.erase("formechange")
		pokemon.boosts.clear()
		pokemon.volatiles.clear()
		pokemon.status_stage = 0
		
	func copy_types_from(pokemon: Pokemon, preterastallized: bool = false):
		var types_data = pokemon.get_types(null, preterastallized)
		var types = types_data[0]
		var added_type = types_data[1]
		add_volatile("typechange", ["/".join(types)])
		if added_type != "":
			add_volatile("typeadd", [added_type])
		else:
			remove_volatile("typeadd")
			
	func get_types(server_pokemon: ServerPokemon = null, preterastallized: bool = false) -> Array:
		var types = []
		if not preterastallized and terastallized != "" and terastallized != "Stellar":
			types = [terastallized]
		elif volatiles.has("typechange"):
			types = volatiles["typechange"][1].split("/")
		else:
			types = ["Normal"]
			
		if has_turnstatus("roost") and types.has("Flying"):
			var new_types = []
			for t in types:
				if t != "Flying": new_types.append(t)
			types = new_types
			if types.is_empty(): types = ["Normal"]
			
		var added_type = volatiles["typeadd"][1] if volatiles.has("typeadd") else ""
		return [types, added_type]
		
	func is_grounded(server_pokemon: ServerPokemon = null) -> bool:
		if volatiles.has("ingrain"): return true
		if volatiles.has("smackdown"): return true
		
		var l_item = server_pokemon.item if server_pokemon else item
		var l_ability = effective_ability(server_pokemon)
		if volatiles.has("embargo") or l_ability == "klutz":
			l_item = ""
			
		if l_item == "ironball": return true
		if l_ability == "levitate": return false
		if volatiles.has("magnetrise") or volatiles.has("telekinesis"): return false
		if l_item == "airballoon": return false
		
		return not get_type_list(server_pokemon).has("Flying")
		
	func effective_ability(server_pokemon: ServerPokemon = null) -> String:
		if fainted: return ""
		return server_pokemon.ability if server_pokemon else ability
		
	func get_type_list(server_pokemon: ServerPokemon = null, preterastallized: bool = false) -> Array:
		var types_data = get_types(server_pokemon, preterastallized)
		var types = types_data[0]
		var added_type = types_data[1]
		if added_type != "":
			types.append(added_type)
		return types
		
	func get_species_forme(server_pokemon: ServerPokemon = null) -> String:
		if volatiles.has("formechange"): return volatiles["formechange"][1]
		return server_pokemon.species_forme if server_pokemon else species_forme
		
	func reset():
		clear_volatile()
		hp = maxhp
		fainted = false
		status = StatusName.NONE
		move_track.clear()
		if name == "": name = species_forme
		
	func hp_width(max_width: int) -> int:
		if fainted or hp == 0: return 0
		if hp == 1 and maxhp > 45: return 1
		
		if maxhp == 48:
			var range_val = Pokemon.get_pixel_range(hp, hpcolor)
			var ratio = (range_val[0] + range_val[1]) / 2.0
			return max(1, round(max_width * ratio))
			
		var percentage = ceil(100.0 * float(hp) / float(maxhp))
		if percentage == 100 and hp < maxhp:
			percentage = 99
		return percentage * max_width / 100

	func get_hp_text(precision: int = 1) -> String:
		return Pokemon.get_hp_text_static(self , false, precision)
		
	static func get_hp_text_static(pokemon: Pokemon, exact_hp: bool, precision: int = 1) -> String:
		if exact_hp: return "%d/%d" % [pokemon.hp, pokemon.maxhp]
		if pokemon.maxhp == 100: return "%d%%" % pokemon.hp
		if pokemon.maxhp != 48:
			return "%.*f" % [precision, 100.0 * float(pokemon.hp) / float(pokemon.maxhp)] + "%"
		var range_val = Pokemon.get_pixel_range(pokemon.hp, pokemon.hpcolor)
		return Pokemon.get_formatted_range(range_val, precision, " - ")
		
	func destroy():
		if sprite: sprite.destroy()
