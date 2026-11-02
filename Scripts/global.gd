extends Node

# PUT SETTINGS STUFF HERE TOO
var font_on = false
var font_btn = null
var dyslexiaFont = load("res://assets/fonts/comici.ttf")
var fontSize = 0 #OK we will adjust the default values later when we implement this
#var masterVolume = 100.0 #Default is 100% I guess
#var sfxVolume = 100.0

var music_off = false
var bgMusic_btn = true

var sfx_off = false
var sfx_btn = true
# User ID defaults to 0 (guest)
var userID = 0

# Score defaults to 0
var score = 0

const sfxSound = preload("res://Assets/audio/Old ROBLOX Splat Tripping Sound.mp3")
