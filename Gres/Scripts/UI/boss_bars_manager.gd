extends Node2D


func _ready() -> void:
	$BloodMother/HPBar.max_value = Global.blood_mother_hp

func _process(delta: float) -> void:
	if Global.boss_mame == "": return
	elif Global.boss_mame == "blood_mother":
		$BloodMother.show()
		$BloodMother/HPBar.value = Global.blood_mother_hp
	elif Global.boss_mame == "gaias_wrath":
		$Wrath.show()
		$Wrath/HPBar.max_value = Global.wrath_max_hp
		$Wrath/HPBar.value = Global.wrath_hp
		$HP_Counter.text = str(Global.wrath_hp)
