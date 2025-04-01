class_name BattleStateFactory


var states = preload("res://scenes/battle_scene/battle_states.gd")

func _init() -> void:
	pass
 
func create_default_start():
	return states.DefaulStart.new()

func create_ally_entry(idx: int = 0, message: String = "", animation = null):
	return states.AllyEntry.new(idx, message, animation)

func create_enemy_entry(idx: int = 0, message: String = "", animation = null):
	return states.EnemyEntry.new(idx, message, animation)

func create_start_turn():
	return states.StartTurn.new()

func create_end_turn():
	return states.EndTurn.new()