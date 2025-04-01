class_name BattleState

var _message: String
var _animation

func _init(message= "", animation= null) -> void:
	_message = message
	_animation = animation

func enter(_battle_context):
	pass

func exit(battle_context):
	battle_context.scene.next_state()

func handle_input(_event):
	pass

func update(_delta):
	
	pass
