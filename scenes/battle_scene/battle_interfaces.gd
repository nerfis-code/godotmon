# Define interfaces para los componentes del sistema de batalla
class_name BattleInterfaces

# Interfaz para la escena de batalla
class IBattleScene extends Node2D:
	func enter_pokemon_by_index(idx: int, is_ally: bool) -> void:
		pass

