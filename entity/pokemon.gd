class_name Pokemon

var species_name: String
var species
var level: int
var abilities: String
var form_index: int = 0
var name: String
var primary_type: String
var secondary_type: String
var stats = DynamicObject.new(
    {
        "ps": -1,
        "attack": -1,
        "defense": -1,
        "speed": -1,
        "sp_attack": -1,
        "sp_defense": -1,
    })
    # 31
var iv = DynamicObject.new(
    {
        "ps": 0,
        "attack": 0,
        "defense": 0,
        "speed": 0,
        "sp_attack": 0,
        "sp_defense": 0,
    })
    # 256
var ev = DynamicObject.new(
    {
        "ps": 0,
        "attack": 0,
        "defense": 0,
        "speed": 0,
        "sp_attack": 0,
        "sp_defense": 0,
    })
var moves = []
enum { PS, ATK, DEF, SPD, SP_ATK, SP_DEF }
func calculate_stats():
    "baseStats"

    var _level = float(level)
    stats.ps = 10+( _level/100 * ((species.baseStats[PS]*2)+iv.ps*4)) + _level + _level *ev.ps/100
    
    stats.attack = 5+( _level /100 * ((species.baseStats[ATK]*2)+iv.attack*4)) + _level *ev.attack/100
    stats.defense = 5+( _level /100 * ((species.baseStats[DEF]*2)+iv.defense*4)) + _level *ev.defense/100
    stats.speed = 5+( _level /100 * ((species.baseStats[SPD]*2)+iv.speed*4)) + _level *ev.speed/100
    stats.sp_attack = 5+( _level /100 * ((species.baseStats[SP_ATK]*2)+iv.sp_attack*4)) + _level *ev.sp_attack/100
    stats.sp_defense = 5+( _level /100 * ((species.baseStats[SP_DEF]*2)+iv.sp_defense*4)) + _level *ev.sp_defense/100

    print(name,stats)

