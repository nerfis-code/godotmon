
func create_pokemon(pokemon_name: String) -> Pokemon:
	var pokemon =  Pokemon.new()
	var specie = _get_specie(pokemon_name)
	pokemon.specie = specie
	pokemon.name = specie.name
	pokemon.specie_name = specie.specie
	pokemon.primaryType = specie.primaryType
	pokemon.secondaryType = specie.secondaryType
	return pokemon
	
func _get_specie(specie_name: String):

	var file_string = FileAccess.open("res://pbs/species/%s.json" % specie_name, FileAccess.READ).get_as_text()
	var json = JSON.new()
	var error = json.parse(file_string)
	if error == OK:
		return DynamicObject.new(json.data)
	else:
		return null
