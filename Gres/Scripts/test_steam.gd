extends SceneTree
func _init():
	var peer = SteamMultiplayerPeer.new()
	print(peer.create_client(1))
	quit()
