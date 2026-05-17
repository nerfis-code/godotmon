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
	func _init(request) -> void:
		pass
		
	static func fix_request(request, battle):
		pass

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
