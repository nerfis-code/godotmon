class_name Pokemon

var species_name: String
var species
var form_index:= 0
var name: String
var primary_type: String
var secondary_type: String
var stats = DynamicObject.new(
    {
        "hp": -1,
        "attack": -1,
        "defense": -1,
        "speed": -1,
        "sp_attack": -1,
        "sp_defense": -1,
    })

