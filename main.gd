extends Node2D

var battle_scene_file = preload("res://scenes/battle_scene/battle_scene.tscn")
var pokemon_factory_file = preload("res://utils/pokemon_factory.gd")


func _ready() -> void:
	var battle_scene = battle_scene_file.instantiate()
	var factory = pokemon_factory_file.new()

	var ctx = BattleContext.new(
			{	
				"scene": battle_scene,
				"state_queue": null,
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
	BattleStateFactory.set_instance(ctx)

	var state_factory = BattleStateFactory.get_instance()
	ctx.state_queue = Queue.new([
		state_factory.create_default_start()
	])
	battle_scene.init(ctx)
	
	get_tree().root.add_child.call_deferred(battle_scene)
