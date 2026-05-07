extends GridContainer

func _ready() -> void:
	if GlobalSteamScript.player_name not in ["Tommo-Pando", "Tommo - Pando"]:
		$icon_22.hide()
	
