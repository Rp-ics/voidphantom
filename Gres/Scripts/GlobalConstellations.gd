extends Node
class_name Global_Constellations

# ===============================
# Dati costellazioni
# ===============================
# Ogni costellazione ha nodi (passive e active) e un bonus finale
const  CONSTELLATIONS := {
	"orion": {
		"nodes": [
			{"id":"orion_p1", "type":"passive", "effect":{"damage_percent":5}, "connected":["orion_p2","orion_a1"]},
			{"id":"orion_p2", "type":"passive", "effect":{"hp_max_plus":20}, "connected":["orion_a2"]},
			{"id":"orion_a1", "type":"active", "effect":"overdrive_shot", "connected":[]},
			{"id":"orion_a2", "type":"active", "effect":"gravity_well", "connected":[]}
		],
		"bonus":{"effect":{"crit_chance":5}}
	},
	"draco": {
		"nodes":[
			{"id":"draco_p1","type":"passive","effect":{"fire_rate_percent":5},"connected":["draco_a1"]},
			{"id":"draco_a1","type":"active","effect":"flame_burst","connected":[]}
		],
		"bonus":{"effect":{"boss_damage_percent":5}}
	},
	"phoenix": {
		"nodes":[
			{"id":"phoenix_p1","type":"passive","effect":{"stamina_bonus":3},"connected":["phoenix_a1"]},
			{"id":"phoenix_a1","type":"active","effect":"phoenix_flame","connected":[]}
		],
		"bonus":{"effect":{"damage_reduction_percent":5}}
	},
	"hydra": {
		"nodes":[
			{"id":"hydra_p1","type":"passive","effect":{"speed_bonus":5},"connected":["hydra_p2"]},
			{"id":"hydra_p2","type":"passive","effect":{"dash_distance_percent":10},"connected":["hydra_a1"]},
			{"id":"hydra_a1","type":"active","effect":"hydra_spike","connected":[]}
		],
		"bonus":{"effect":{"low_hp_shield":15}}
	},
	"leviathan": {
		"nodes":[
			{"id":"leviathan_p1","type":"passive","effect":{"aoe_percent":10},"connected":["leviathan_a1"]},
			{"id":"leviathan_a1","type":"active","effect":"leviathan_torrent","connected":[]}
		],
		"bonus":{"effect":{"ability_aoe_percent":10}}
	}
}

# ===============================
# FUNZIONI UTILI
# ===============================

# Restituisce info nodo da ID
func get_node_info(skill_id: String) -> Dictionary:
	for const_key in CONSTELLATIONS.keys():
		for n in CONSTELLATIONS[const_key]["nodes"]:
			if n["id"] == skill_id:
				return n
	return {}

# Restituisce info costellazione da ID nodo
func get_constellation_of_node(skill_id: String) -> String:
	for const_key in CONSTELLATIONS.keys():
		for n in CONSTELLATIONS[const_key]["nodes"]:
			if n["id"] == skill_id:
				return const_key
	return ""

# Restituisce bonus finale della costellazione
func get_constellation_bonus(const_key: String) -> Dictionary:
	if CONSTELLATIONS.has(const_key):
		return CONSTELLATIONS[const_key].bonus
	return {}
