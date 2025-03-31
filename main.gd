extends Node2D

func _ready() -> void:
	var fatory = load("res://utils/pokemon_factory.gd").new()
	fatory.create_pokemon("pikachu")
