extends Node

func play_sound(stream: AudioStream) -> void:
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = stream
	add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)
