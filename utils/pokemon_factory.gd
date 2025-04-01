
func create_pokemon(pokemon_name: String) -> Pokemon:
	var pokemon =  Pokemon.new()
	var species = _get_specie(pokemon_name)
	pokemon.species = species
	pokemon.name = species.name
	pokemon.species_name = species.species
	pokemon.primary_type = species.primaryType
	pokemon.secondary_type = species.secondaryType
	return pokemon
	
func _get_specie(specie_name: String):

	var file_string = FileAccess.open("res://pbs/species/%s.json" % specie_name.to_upper(), FileAccess.READ).get_as_text()
	var json = JSON.new()
	var error = json.parse(file_string)
	if error == OK:
		return DynamicObject.new(json.data)
	else:
		return null

func create_random_pokemon():
	return create_pokemon(["bulbasaur","pikachu","charmander"][randi_range(0,2)])
