extends Control

var time_im = Global.player_immunity_time
var time_ti = GlobalStats.time_slow_time

func _ready() -> void:
	$BonusContainer/heal.hide()
	$BonusContainer/stamina.hide()
	$BonusContainer/shield.hide()
	$BonusContainer/time.hide()
	
	time_im = Global.player_immunity_time
	time_ti = GlobalStats.time_slow_time
	
	# Mi connetto al segnale globale UNA SOLA VOLTA
	Global.connect("bonus_touched", Callable(self, "_on_bonus_touched"))

func _on_bonus_touched(bonus_type: String) -> void:
	if GlobalStats.shield_bonus == 1:Global.player_immunity_time = 0.5
	elif GlobalStats.shield_bonus == 2:Global.player_immunity_time = 1.5
	elif GlobalStats.shield_bonus == 3:Global.player_immunity_time = 3.0
	if GlobalStats.time_slow_bonus == 1:GlobalStats.time_slow_time = 0.5
	elif GlobalStats.time_slow_bonus == 2:GlobalStats.time_slow_time = 1.5
	elif GlobalStats.time_slow_bonus == 3:GlobalStats.time_slow_time = 3
	time_im = Global.player_immunity_time
	time_ti = GlobalStats.time_slow_time
	
	if Global.player_immunity: 
		$BonusContainer/shield.show()
		$BonusContainer/shield/Time.text = str(time_im)
		
		$ImmuneCD.wait_time = Global.player_immunity_time
		$ImmuneCD.start()
		$ImmuneSec.start()
		
	if GlobalStats.time_slow: 
		$BonusContainer/time.show()
		$BonusContainer/time/Time.text = str(time_ti)
		
		$TimeCd.wait_time = GlobalStats.time_slow_time
		$TimeCd.start()
		$TimeSec.start()
	
func _on_immune_cd_timeout() -> void:
	$BonusContainer/shield.hide()

func _on_time_cd_timeout() -> void:
	$BonusContainer/time.hide()

func _on_immune_sec_timeout() -> void:
	$BonusContainer/shield/Time.text = str(time_im)
	time_im -= 0.1
	if time_im <= 0:
		time_im = 0
		$ImmuneSec.stop()
	else:
		$ImmuneSec.start()

func _on_time_sec_timeout() -> void:
	$BonusContainer/time/Time.text = str(time_ti)
	time_ti -= 0.1
	if time_ti <= 0:
		time_ti = 0
		$TimeSec.stop()
	else:
		$TimeSec.start()
