class_name BattleStateFactory

var _ctx: BattleContext
var states = preload("res://scenes/battle_scene/battle_states.gd")

static var instance: BattleStateFactory

static func get_instance() -> BattleStateFactory:
	return instance if instance else null
	
static func set_instance(ctx) -> void:
	instance = BattleStateFactory.new(ctx)

func _init(ctx) -> void:
	_ctx = ctx

func create_default_start():
	var state = states.DefaulStart.new()
	state.ctx = _ctx
	return state

func create_ally_entry(idx: int = 0):
	var state = states.AllyEntry.new()
	state._idx = idx
	state.ctx = _ctx
	return state

func create_enemy_entry(idx: int = 0):
	var state = states.EnemyEntry.new()
	state._idx = idx
	state.ctx = _ctx
	return state

func create_start_turn():
	var state = states.StartTurn.new()
	state.ctx = _ctx
	return state

func create_end_turn():
	var state = states.EndTurn.new()
	state.ctx = _ctx
	return state