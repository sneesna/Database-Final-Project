extends Control

const LARGE_TEXT_SIZE = 32

var music = Global.music_off
var sfx_off = Global.sfx_off
var blips_off = Global.blips_off
var bgBtnState = Global.bgMusic_btn
var sfxBtnState = Global.sfx_btn
var blipsBtnState = Global.blips_btn
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#volumes
	$bgMusic.button_pressed = Global.bgMusic_btn
	$sfxVol.button_pressed = Global.sfx_btn
	$blipsVol.button_pressed = Global.blips_btn
	_restore_text_settings()
	pass

	#set the actual volumes of the back and click sfx
	#var sfxVol = 1*(Global.masterVolume/100)*(Global.sfxVolume/100)
	#$clickSFX.set_volume_linear(sfxVol)
	#$backSFX.set_volume_linear(sfxVol)

func _process(_delta: float) -> void:
	pass

#Travel back to menu
func _on_back_btn_pressed() -> void:
	
	_on_cancel_settings_pressed()
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")
	Sfx.play()

func _on_cancel_settings_pressed() -> void:
	
	#set all settings back to how it was before
	music = Global.music_off
	$bgMusic.button_pressed = bgBtnState
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),Global.music_off)
	
	sfx_off = Global.sfx_off
	$sfxVol.button_pressed = sfxBtnState
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"),Global.sfx_off)
	#AudioManager.play_sound(Global.sfxSound)
	
	blips_off = Global.blips_off
	$blipsVol.button_pressed = blipsBtnState
	
	_restore_text_settings()
	
	Sfx.play()
	##$bgMusic.value = Global.musicVolume
	##$sfxVol.value = Global.sfxVolume

func _on_save_settings_pressed() -> void:
	
	#save settings to the global variables
	Global.music_off = music
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),Global.music_off)
	bgBtnState = $bgMusic.button_pressed
	
	Global.sfx_off = sfx_off
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"),Global.sfx_off)
	sfxBtnState = $sfxVol.button_pressed
	
	Global.blips_off = blips_off
	blipsBtnState = $blipsVol.button_pressed
	
	Global.font_on = $dysFont.button_pressed
	Global.fontSize = LARGE_TEXT_SIZE if $largeText.button_pressed else 0
	Global.font_btn = Global.dyslexiaFont if Global.font_on else null
	ThemeDB.get_default_theme().default_font = Global.font_btn
	
	
	#Global.sfxVolume = $sfxVol.value
	#AudioManager.play_sound(Global.sfxSound)
	Sfx.play()
	#recalculating the volume
	#var sfxVol = 1*(Global.masterVolume/100)*(Global.sfxVolume/100)
	##$clickSFX.set_volume_linear(sfxVol)
	##$backSFX.set_volume_linear(sfxVol)
"""
#Larger Font Size Toggle
func _on_check_button_toggled(toggled_on: bool) -> void:
	#Sound Effects
	$clickSFX.play()
	#Load in Themes for text sizing
	#var settings_theme = preload("res://settings_theme.tres")
	#var quiz_theme = preload("res://quiz_theme.tres")
	#var score_values_theme = preload("res://scoreboard_rank_theme.tres")
	#var results_label_theme = preload("res://results_label_theme.tres")
	#var results_text_theme = preload("res://results_text_theme.tres")

	if(toggled_on == true):
		settings_theme.set_font_size("font_size", "Label", 34)
		settings_theme.set_font_size("font_size", "CheckButton", 34)
		quiz_theme.set_font_size("normal_font_size", "RichTextLabel", 35)
		score_values_theme.set_font_size("font_size", "Label", 36)
		results_label_theme.set_font_size("normal_font_size", "RichTextLabel", 50)
		results_label_theme.set_font_size("normal_font_size", 38)
		
	else:
		settings_theme.set_font_size("font_size", "Label", 24)
		settings_theme.set_font_size("font_size", "CheckButton", 24)
		quiz_theme.set_font_size("normal_font_size", "RichTextLabel", 28)
		score_values_theme.set_font_size("font_size", "Label", 26)
		results_label_theme.set_font_size("normal_font_size", "RichTextLabel", 40)
		results_text_theme.set_font_size("normal_font_size", "RichTextLabel", 28)

"""

func _restore_text_settings() -> void:
	$dysFont.set_pressed_no_signal(Global.font_on)
	$largeText.set_pressed_no_signal(Global.fontSize > 0)
	ThemeDB.get_default_theme().default_font = Global.dyslexiaFont if Global.font_on else null


func _on_dys_font_toggled(toggled_on: bool) -> void:
	Sfx.play()
	ThemeDB.get_default_theme().default_font = Global.dyslexiaFont if toggled_on else null


func _on_bg_music_toggled(toggled_on: bool) -> void:
	#AudioManager.play_sound(Global.sfxSound)
	Sfx.play()
	if (toggled_on == false):
		music = true
		Global.bgMusic_btn = toggled_on
		#bgBtnState = toggled_on
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),music)
	else:
		music = false
		Global.bgMusic_btn = toggled_on
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),music)
	
	pass # Replace with function body.


func _on_sfx_vol_toggled(toggled_on: bool) -> void:
	#AudioManager.play_sound(Global.sfxSound)
	Sfx.play()
	if (toggled_on == false):
		sfx_off = true
		Global.sfx_btn = toggled_on
		#bgBtnState = toggled_on
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"),sfx_off)
	else:
		sfx_off = false
		Global.sfx_btn = toggled_on
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"),sfx_off)
	
	pass # Replace with function body.


func _on_blips_vol_toggled(toggled_on: bool) -> void:
	Sfx.play()
	if (toggled_on == false):
		blips_off = true
		Global.blips_btn = toggled_on
	else:
		blips_off = false
		Global.blips_btn = toggled_on
	
	pass # Replace with function body.
