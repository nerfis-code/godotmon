class_name Battler
extends Node2D

var _sprite: Sprite2D
var _pokemon: Pokemon
var _scene: Node2D
var is_ally: bool

#battle
var idx: int

func _init(props) -> void:
	_pokemon = props.pokemon
	_scene = props.scene
	is_ally = props.is_ally
	position = props.position

	# sprite
	_sprite = Sprite2D.new()
	var perfil = "back" if is_ally else "front"
	var sprite_path = "res://graphics/battlers/%s/%s.png"% [perfil,_pokemon.species_name]
	if FileAccess.file_exists(sprite_path):
		_sprite.texture = load(sprite_path)    
	else: 
		_sprite.texture = load("res://graphics/battlers/Back/000.png")    
	
	add_child(_sprite)
