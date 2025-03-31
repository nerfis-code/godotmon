extends Node2D

var battle_scene_file = preload("res://scenes/battle_scene/battle_scene.tscn")
var pokemon_factory_file = preload("res://utils/pokemon_factory.gd")


var default = Queue.new([preload("res://scenes/battle_scene/states/player_entrance.gd").new()])

func _ready() -> void:
	var battle_scene = battle_scene_file.instantiate()
	var factory = pokemon_factory_file.new()
	battle_scene.init(
		DynamicObject.new(
			{
				"state_queue": default,
				"battle_type":battle_scene.WILD,
				"player": Player,
				"player_party": Player.party,
				"enemy": null,
				"enemy_party": [
					factory.create_random_pokemon(),
					factory.create_random_pokemon()
					],
			}
		)
	)
	get_tree().root.add_child.call_deferred(battle_scene)
