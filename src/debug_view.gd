extends Node2D

var battle: Battle
@onready var label: Label = $CanvasLayer/Label

func _ready() -> void:
	battle = Battle.new()
	battle.initdone.connect(_on_init_done)

func _on_init_done() -> void:
	print("init done")
	label.text = battle.my_side["pokemon"][0].ident
