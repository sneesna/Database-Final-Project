# Dialogue box

A dialogue box with character names, optional portraits, typing sounds, and the gold background included in `assets/dialogue_background.webp`.

## Add it to a scene

Drag `dialogue_box.tscn` into your scene. You can also enable **dialogue_box** in **Project Settings > Plugins**, then add a **DialogueBox** node. Both options build the same UI.

Keep it in a full-size Control, or put it under a CanvasLayer for dialogue over your game. The box resizes with its parent and stays near the bottom.

Set `char_name`, `dialogue_lines`, and optionally `char_image` in the Inspector. `auto_start` is on by default, so these lines start when the node is ready. Turn it off if an NPC or trigger should start the conversation later.

```gdscript
@onready var dialogue = $CanvasLayer/DialogueBox

func talk_to_npc() -> void:
	dialogue.start_dialogue("Guide", [
		"Hey! Welcome to the game.",
		"[b]Good luck[/b] with your first challenge!"
	])
```

Pass a texture as the third argument to show a portrait:

```gdscript
dialogue.start_dialogue("Guide", ["Ready to go?"], guide_portrait)
```

Leaving out the portrait clears the previous one when that speaker starts. An empty character name hides the name box. An empty list finishes as soon as its turn comes up.

## Switch speakers from code

Turn off `auto_start` if the script supplies the opening lines. Calls on the same box play in order, so this works in your scene's `_ready()`:

```gdscript
func _ready() -> void:
	$DialogueBox.start_dialogue("1st", ["i am the one that goes first"])
	$DialogueBox.start_dialogue("2nd", ["i run second", "yay"])
```

Use `await` when the next bit of code should wait for a speaker. It returns `true` when their last line closes or `finish_dialogue()` is called. Cancelling the dialogue returns `false` for that speaker and anyone still waiting.

```gdscript
if await $DialogueBox.start_dialogue("Judge", ["Court is in session."]):
	await get_tree().create_timer(1.0).timeout
	$DialogueBox.start_dialogue("You", ["Ready, Your Honor."])
```

## Read and advance

Click **Show all**, press **Enter**, or use the gamepad accept button to reveal the current line. Press again to move to the next line or speaker. The final speaker's last line has a **Close** button.

`advance_action` defaults to Godot's `ui_accept`. You can set it to another action from the Input Map. `next_line()` does the same thing from code.

Set `characters_per_second` to change the typing speed. Set it to `0` to show each line immediately. `reveal_current_line()` also shows the whole current line.

BBCode is enabled by default. Turn off `bbcode_enabled` if text should be displayed literally. Long lines scroll inside the box; use the mouse wheel or scrollbar to read them.

## React to dialogue

The node has these signals:

| Signal | When it runs |
| --- | --- |
| `dialogue_started` | A conversation starts. |
| `line_started(index, text)` | A line starts displaying. The first index is `0`. |
| `line_finished(index, text)` | A line is fully visible, including when typing is skipped. |
| `dialogue_finished` | The last line closes, or `finish_dialogue()` is called. |
| `dialogue_cancelled` | `cancel_dialogue()` is called, or an active box is hidden. |

`dialogue_finished` fires once per speaker. `finish_dialogue()` skips the rest of that speaker's lines and moves to the next speaker. Use `cancel_dialogue()` when the player walks away or you want to clear the whole queue before starting a different conversation.

`is_active`, `is_typing`, and `current_line` are available if you need to check its state.

## Appearance and settings

The Inspector has options for the background texture, text/name/button font sizes, and the **Show all**, **Next**, and **Close** labels.

The add-on works without any autoloads. If `/root/Global` exists, it reads these optional settings: `font_on`, `dyslexiaFont`, `fontSize`, `masterVolume`, `sfxVolume`, `blips_off`, and `sfx_off`. Missing settings use the values on the DialogueBox node. Volume values use `0` to `100`; `fontSize = 0` uses the individual font sizes.

Change `settings_path` to use a different settings node, or clear it to use only the local Inspector values. Call `update_settings()` after changing font or sound preferences. Settings are also refreshed for each line and typing sound.

The optional `click_sound_path` defaults to `/root/Sfx`. If that node has a `play()` method, advancing plays its sound. Clear the path to disable it. Typing sounds use the `SFX` bus when available and fall back to `Master`.

## Use it in another project

Copy the whole `addons/dialogue_box` folder into the other project's `addons` folder, then let Godot import its assets. Instance the scene, or enable its plugin to use **Add Node**. No files outside this folder are needed.
