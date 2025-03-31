extends Node

enum {MALE, FEMALE}

var factory_file = preload('res://utils/pokemon_factory.gd')

var trainer_name:= 'nerfis'
var id
var uid
var party: Array
var gender: int = MALE
var money
var medals

func _ready() -> void:
	var factory = factory_file.new()
	party = [
		factory.create_pokemon("pikachu"),
		factory.create_pokemon("charizard"),
	]
