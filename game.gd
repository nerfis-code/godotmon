extends Node2D

@onready var text_edit: TextEdit = $UI/TextEdit

var sim_controller: SimController

func _ready() -> void:
	sim_controller = SimController.new(_on_message_received)

func _on_message_received(message: String):
	text_edit.text += message + "\n"

func _on_move_pressed(extra_arg_0: int) -> void:
	sim_controller.push_command("move " + str(extra_arg_0))
