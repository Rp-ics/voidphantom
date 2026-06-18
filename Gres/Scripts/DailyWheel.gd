extends Node

var save_path := "user://daily_wheel.save"

var free_spins: int = 0
var last_spin_day: int = -1
var boosted_spins_left := 60
var special_event := true
var skin_ids := {
	"Common Skin": [12, 12, 12],  # body, props, wings
	"Rare Skin":   [14, 14, 14],
	"Epic Skin":   [13, 13, 13]
}

# PREMI
var slots := [
	{"name": "HELLWING", "type": "weapon", "amount": 1, "weight": 50},     # 0.05-0.1%
	{"name": "Gold", "type": "currency", "amount": 600, "weight": 80000},        # 80%
	{"name": "Gold", "type": "currency", "amount": 1200, "weight": 60000},       # 60%
	{"name": "Tablet", "type": "special", "amount": 1, "weight": 30000},         # 30%
	{"name": "Tablet", "type": "special", "amount": 2, "weight": 18000},         # 18%
	{"name": "Shards", "type": "material", "amount": 2, "weight": 50000},        # 50%
	{"name": "Shards", "type": "material", "amount": 6, "weight": 15000},        # 15%
	{"name": "Shards", "type": "material", "amount": 10, "weight": 10000}        # 10%
]

var slots_event := [
	{"name": "Epic Skin", "type": "weapon", "amount": 1, "weight": 50},     # 0.05-0.1%
	{"name": "Gold", "type": "currency", "amount": 800, "weight": 60000},        # 60%
	{"name": "Gold", "type": "currency", "amount": 1800, "weight": 15000},        # 15%
	{"name": "Tablet", "type": "special", "amount": 2, "weight": 80000},        # 80%
	{"name": "Common Skin", "type": "weapon", "amount": 1, "weight": 30000},    # 30%
	{"name": "Shards", "type": "material", "amount": 4, "weight": 50000},        # 50%
	{"name": "Rare Skin", "type": "weapon", "amount": 1, "weight": 18000},         # 18%
	{"name": "Shards", "type": "material", "amount": 10, "weight": 10000}        # 10%
]

func _ready():
	if special_event: slots = slots_event
	_load()
	_check_daily_reset()

func _check_daily_reset():
	var today = Time.get_date_dict_from_system().day

	# primo avvio
	if last_spin_day == -1:
		free_spins = 1
		last_spin_day = today
		save()
		return

	# nuovo giorno → nuovo spin gratis
	if today != last_spin_day:
		free_spins += 1   # come 8 Ball Pool, accumulabile
		last_spin_day = today
		save()

func has_free_spin() -> bool:
	return free_spins > 0

func consume_free_spin():
	if free_spins > 0:
		free_spins -= 1
		save()


# -----------------------------------
# PICK RANDOM REWARD
# -----------------------------------
func spin_wheel() -> Dictionary:
	var total_weight := 0
	
	for slot in slots:
		total_weight += slot.weight

	var r := randi() % total_weight
	var cumulative := 0

	for slot in slots:
		cumulative += slot.weight
		if r < cumulative:
			return slot

	return slots[0]
	
# -----------------------------------
# APPLY REWARD
# -----------------------------------
func apply_reward(reward: Dictionary):
	match reward.type:
		"material":
			GlobalStats.ice_shard += reward.amount
			GlobalStats.void_shard += reward.amount
			GlobalStats.magma_shard += reward.amount
			GlobalStats.light_shard += reward.amount
			# Lista di tutti gli shard
			var shards := ["ice_shard", "void_shard", "magma_shard", "light_shard"]
			for shard_name in shards:
				var shard_val = GlobalStats.get(shard_name)
				if shard_val > 99:
					var excess = shard_val - 99
					GlobalStats.set(shard_name, 99)  # mantieni max 99
					GlobalStats.gold += int(excess * 1.6)
		"currency":
			GlobalStats.gold += reward.amount
			if reward.amount == 800:
				GlobalStats.ice_shard += 2
				GlobalStats.void_shard += 2
				GlobalStats.magma_shard += 2
				GlobalStats.light_shard += 2
			elif reward.amount == 1800:
				GlobalStats.ice_shard += 6
				GlobalStats.void_shard += 6
				GlobalStats.magma_shard += 6
				GlobalStats.light_shard += 6
				# Lista di tutti gli shard
			var shards := ["ice_shard", "void_shard", "magma_shard", "light_shard"]
			for shard_name in shards:
				var shard_val = GlobalStats.get(shard_name)
				if shard_val > 99:
					var excess = shard_val - 99
					GlobalStats.set(shard_name, 99)  # mantieni max 99
					GlobalStats.gold += int(excess * 1.6)
		"weapon":
			apply_skin_reward(reward.name)
		"special":
			GlobalStats.tablet += reward.amount
	save()

func apply_skin_reward(reward_name: String) -> Dictionary:
	if not skin_ids.has(reward_name):
		return {"status": "invalid"}

	var ids = skin_ids[reward_name]
	var already_unlocked := true

	for id in ids:
		if id in Global.LOCKED_BODIES or id in Global.LOCKED_PROPS or id in Global.LOCKED_WINGS:
			already_unlocked = false
			break

	if already_unlocked:
		var shards = ["ice_shard", "void_shard", "magma_shard", "light_shard"]
		var random_shard = shards[randi() % shards.size()]
		GlobalStats.set(random_shard, GlobalStats.get(random_shard) + 1)

		return {
			"status": "duplicate",
			"shard": random_shard
		}
	else:
		for id in ids:
			if id in Global.LOCKED_BODIES:
				Global.LOCKED_BODIES.erase(id)
			elif id in Global.LOCKED_PROPS:
				Global.LOCKED_PROPS.erase(id)
			elif id in Global.LOCKED_WINGS:
				Global.LOCKED_WINGS.erase(id)

		return {
			"status": "unlocked",
			"ids": ids
		}

# -----------------------------------
# PUBLIC SPIN API
# -----------------------------------
func try_spin(gem_cost: int) -> Dictionary:
	# controllo tempo (anti cheat)
	if not TimeManager.check_time_validity():
		return {"error": "TIME_CHEAT"}

	# gratuito?
	if has_free_spin():
		consume_free_spin()
	else:
		# non hai free spin → usa gemme
		if Global.spin_gem < gem_cost:
			return {"error": "NO_GEMS"}
		Global.spin_gem -= gem_cost

	var reward = spin_wheel()
	apply_reward(reward)

	return reward


# -----------------------------------
# SAVE / LOAD
# -----------------------------------
func save():
	var data = {
		"free_spins": free_spins,
		"last_spin_day": last_spin_day,
		"boosted_spins_left": boosted_spins_left
	}
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(data)
	file.close()

func _load():
	if not FileAccess.file_exists(save_path):
		save()
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	var data = file.get_var()
	file.close()

	free_spins = data.get("free_spins", 1)
	last_spin_day = data.get("last_spin_day", -1)
	boosted_spins_left = data.get("boosted_spins_left", boosted_spins_left)
